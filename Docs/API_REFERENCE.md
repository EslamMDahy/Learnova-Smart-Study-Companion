# Learnova - API Reference

## 1. Overview

This document provides a structured reference for the currently implemented backend API in Learnova.

It focuses on:
- what each endpoint does
- what it expects
- what it returns
- who is allowed to access it
- the main validation and error rules that matter at integration time

This is a practical API reference, not a low-level implementation document.  
For backend design decisions, architecture boundaries, and internal workflow details, refer to `BACKEND_ARCHITECTURE.md`.

---

## 2. API Conventions

### Base Style
- The API is organized by feature domain.
- Routes are not versioned.
- Request and response bodies are JSON unless the endpoint explicitly uses file upload.
- Protected endpoints rely on JWT-based authentication.
- Session continuation uses a refresh-token cookie flow.

### Authentication Header
Protected endpoints expect a Bearer token in the `Authorization` header:

```http
Authorization: Bearer <access_token>
```

### Response Style
The API generally returns:
- resource-shaped objects for create/get/update endpoints
- wrapper objects for list endpoints
- message-based responses for token and workflow actions
- `204 No Content` for successful delete operations

### File Upload Notes
Some file workflows are staged:
- request upload authorization or upload target first
- upload the file
- confirm the upload in a follow-up endpoint

This pattern is used to keep file state under backend control.

---

## 3. Authorization Model

Authorization in Learnova is based on more than just role names.  
The backend combines:

- authenticated identity
- system role
- course ownership
- enrollment state
- resource hierarchy validation
- token-backed workflow state where applicable

### Main Roles
- **Instructor**: manages instructional content and course structure
- **Student**: consumes content through enrollment-based access
- **Owner**: used mainly in organization-related flows
- **Assistant**: currently allowed during registration, but not a central operational role in the main platform flow

### Practical Access Patterns
In general:

- **Instructor-only endpoints** are usually also **ownership-restricted**
- **Student read access** usually requires valid enrollment in the relevant course
- **Organization endpoints** are not part of the main active product flow and should be treated as limited/demo-oriented
- Some flows depend on **special-purpose tokens**, such as:
  - email verification
  - password reset
  - invitation acceptance
  - delete-account OTP confirmation

---

## 4. Common Error Behavior

The exact error text may vary by endpoint, but the API generally follows these patterns:

- **400 Bad Request**
  - invalid payload shape
  - invalid business input
  - unsupported type-specific input
  - invalid relationship values

- **401 Unauthorized**
  - missing token
  - invalid token
  - expired token
  - unauthenticated access to protected endpoints

- **403 Forbidden**
  - wrong role
  - not the owner of the target course/resource
  - not enrolled where enrollment is required
  - invalid access context despite valid authentication

- **404 Not Found**
  - target entity does not exist
  - entity does not exist within the expected hierarchy

- **409 Conflict**
  - duplicate registration or conflicting state transitions in workflow-style endpoints

- **422 Unprocessable Entity**
  - invalid identifiers
  - invalid file metadata
  - malformed business payload that passes transport parsing but fails stricter validation

---

## 5. Authentication

### `POST /auth/register`
Create a new user account.

**Request**
- `full_name`
- `email`
- `password`
- `system_role` (optional)

**Response**
- account creation result

**Authorization**
- Public

**Notes**
- Password minimum length is enforced.
- Registration may reject duplicate or conflicting account states.
- `system_role` is optional in the request model.

**Example**
```json
{
  "full_name": "Ahmed Ali",
  "email": "ahmed@example.com",
  "password": "StrongPass123",
  "system_role": "instructor"
}
```

---

### `POST /auth/send-verification-email`
Send or resend an email verification message.

**Request**
- `email`

**Response**
- `message`
- `email_sent`

**Authorization**
- Public

**Notes**
- Used after registration or when the user needs another verification email.

---

### `GET /auth/verify-email`
Verify an email address using a token.

**Query Parameters**
- `token`

**Response**
- verification result

**Authorization**
- Public

**Notes**
- This endpoint is token-driven rather than session-driven.

---

### `POST /auth/check-email-verified`
Check whether an email has already been verified.

**Request**
- `email`

**Response**
- `is_verified`

**Authorization**
- Public

**Notes**
- Designed for frontend verification flow support.
- Unknown emails return a safe boolean-style result rather than exposing user existence details.

---

### `POST /auth/login`
Authenticate a user and start a session.

**Request**
- `email`
- `password`
- `remember_me`

**Response**
- access token and user-facing login data
- refresh token is handled through cookie-based session flow

**Authorization**
- Public

**Notes**
- Returns a Bearer-style access token for protected API use.
- Also participates in refresh-token session handling.

**Example**
```json
{
  "email": "ahmed@example.com",
  "password": "StrongPass123",
  "remember_me": true
}
```

---

### `GET /auth/me`
Return the currently authenticated user.

**Response**
- current user object

**Authorization**
- Authenticated user

**Notes**
- Useful for restoring session state on the client.

---

### `POST /auth/refresh`
Refresh the access token using the refresh-token cookie.

**Response**
- new access token or refreshed authentication result

**Authorization**
- Requires valid refresh-token cookie

**Notes**
- This endpoint is part of the session-renewal flow.
- It does not rely on a Bearer token in normal usage.

---

### `POST /auth/logout`
Terminate the current session.

**Response**
- logout result

**Authorization**
- Session-aware request

**Notes**
- Typically clears or invalidates refresh-token state.

---

### `POST /auth/forgot-password`
Request a password reset email.

**Request**
- `email`

**Response**
- `message`

**Authorization**
- Public

**Notes**
- Token-based reset flow starts here.

---

### `POST /auth/reset-password`
Reset the account password using a reset token.

**Request**
- `token`
- `new_password`

**Response**
- `message`

**Authorization**
- Public token-backed flow

**Notes**
- Existing tokens may become invalid after password change.
- Access tokens are effectively revoked through password-change-aware validation logic.

---

## 6. Courses

### `POST /courses`
Create a new course.

**Request**
- `course_type`
- `organization_id` (required for organization-type courses)
- `title`
- `course_code` (optional)
- `description` (optional)
- `is_open_for_enrollment`
- `visibility_level`
- `requires_enrollment_approval`
- `tags` (optional)
- `category` (optional)
- `status` (optional)

**Response**
- created course object

**Authorization**
- Instructor-oriented protected endpoint  
- Course creation is tied to the authenticated user context

**Notes**
- `course_type` and `organization_id` must match the schema rules.
- Open enrollment and controlled access are both supported at the course level.

**Example**
```json
{
  "course_type": "individual",
  "title": "Database Systems",
  "course_code": "DB-301",
  "description": "Introductory database course",
  "is_open_for_enrollment": false,
  "visibility_level": "private",
  "requires_enrollment_approval": false,
  "tags": ["database", "sql"],
  "category": "Computer Science",
  "status": "draft"
}
```

---

### `POST /courses/{course_id}/invitations/upload`
Upload an Excel sheet containing emails for controlled course invitations.

**Request**
- multipart form-data
- `file` (`.xlsx`)
- `sheet_name` (optional)
- `email_column` (optional, defaults to `email`)

**Response**
- upload summary including:
  - total rows
  - extracted emails
  - inserted invitations
  - skipped existing emails
  - invalid emails

**Authorization**
- Instructor only  
- Must be the owner of the target course

**Notes**
- This endpoint prepares invitation records; it does not send the invitation emails by itself.
- Designed for controlled enrollment flows.

---

### `POST /courses/{course_id}/invitations/send`
Send course invitation emails.

**Request**
- `email` (optional, for sending/resending to one target)
- `include_expired`
- `force`

**Response**
- send summary including:
  - sent count
  - skipped count
  - failed count
  - attempted count
  - optional target email
  - optional samples

**Authorization**
- Instructor only  
- Must own the target course

**Notes**
- Can resend to pending and optionally expired invitations.
- Accepted or ineligible invitation states may be skipped.

---

### `POST /courses/invitations/accept`
Accept a course invitation using an invitation token.

**Request**
- `token`

**Response**
- acceptance result
- `course_id`
- `enrollment_id` (when applicable)
- `enrolled`
- `accepted_at`

**Authorization**
- Authenticated user  
- Intended for the invited user

**Notes**
- This is a token-backed workflow.
- The endpoint is protected, so the user must be logged in when accepting.

---

### `GET /courses/my`
List courses visible to the current user.

**Response**
- `items`
- `total`

**Authorization**
- Authenticated user

**Notes**
- Used to retrieve the user’s current course space.
- Returned items include useful metadata such as:
  - course type
  - visibility
  - status
  - optional dashboard counts

---

### `GET /courses/{course_id}/invitations`
List invitation records for a course.

**Query Parameters**
- `limit`
- `offset`

**Response**
- `course_id`
- `total`
- `items`

**Authorization**
- Instructor only  
- Must own the course

**Notes**
- Supports invitation monitoring and resend-oriented UI flows.

---

### `PATCH /courses/{course_id}`
Update course metadata.

**Request** (all fields optional)
- `title`
- `description`
- `category`
- `course_code`
- `is_open_for_enrollment`
- `requires_enrollment_approval`
- `visibility_level`
- `tags`

**Response**
- full course object (same shape as `MyCourseItem`)

**Authorization**
- Instructor — course owner only

**Notes**
- Follows the project-wide dynamic update pattern: `null` = ignore field, whitespace-only string = clear the value, actual value = update.

---

### `POST /courses/{course_id}/publish`
Publish a course, making it visible according to its `visibility_level`.

**Response**
- `id`
- `status`
- `message`

**Authorization**
- Instructor — course owner only

**Notes**
- A draft course is not visible to anyone. Publishing activates visibility rules based on `visibility_level`.
- After publishing: `public` courses appear in search; `unlisted` courses are accessible via direct link only; `private` courses are accessible to enrolled users only.
- Enrollment is only possible on published courses.

---

### `POST /courses/{course_id}/cover/initiate`
Request a signed upload URL for a course cover image.

**Request**
- `content_type`
- `file_size_bytes`

**Response**
- `upload_url`
- `path`
- `token`
- `content_type`
- `max_bytes`

**Authorization**
- Instructor — course owner only

**Notes**
- Same staged upload pattern used for avatars and materials.

---

### `POST /courses/{course_id}/cover/confirm`
Confirm course cover upload completion.

**Response**
- `cover_url`
- `updated_at`

**Authorization**
- Instructor — course owner only

**Notes**
- Finalizes the cover update. The `cover_url` is returned and reflected in subsequent course listing responses.

---

### `POST /courses/{course_id}/enroll`
Enroll the current student in a course.

**Response**
- `enrollment_id`
- `course_id`
- `status`
- `enrollment_type`
- `enrolled_at`

**Authorization**
- Student only

**Notes**
- Only available for published courses.
- If `requires_enrollment_approval` is true, enrollment status is `pending` until approved by the instructor.
- If `is_open_for_enrollment` is false, enrollment is not permitted.

---

### `GET /courses/{course_id}/enrollment-requests`
List pending enrollment requests for a course.

**Response**
- `course_id`
- `total`
- `requests`: list of `{ enrollment_id, student_id, full_name, email, status, enrolled_at }`

**Authorization**
- Instructor — course owner only

---

### `PATCH /courses/{course_id}/enrollment-requests/{enrollment_id}`
Approve or decline an enrollment request.

**Request**
- `status`: `approved` | `declined`

**Response**
- `enrollment_id`
- `status`

**Authorization**
- Instructor — course owner only

---

### `GET /courses/search`
Search published courses.

**Query Parameters**
- `q` (required)
- `limit` (default: 20)
- `offset` (default: 0)

**Response**
- `total`
- `limit`
- `offset`
- `results`: list of `{ id, title, description, category, tags, cover_image_key, banner_image_key, enrollment_count, average_rating, requires_enrollment_approval }`

**Authorization**
- Authenticated user

**Notes**
- Only returns published courses.
- Results are ranked by relevance using pre-computed search weights stored via a DB trigger on course creation/update.
- `public` visibility only — `private` and `unlisted` courses do not appear in search results.

---

### `GET /courses/search/autocomplete`
Return autocomplete suggestions for a course search query.

**Query Parameters**
- `q` (required)

**Response**
- `suggestions`: list of strings (up to 10 matching course titles)

**Authorization**
- Authenticated user

**Notes**
- Returns prefix-matched course title suggestions from the database.
- Intended for real-time search-as-you-type UI flows.

---

## 7. Learning Outcomes

All learning outcome routes are nested under a course.

### `POST /courses/{course_id}/learning-outcomes`
Create a learning outcome under a course.

**Request**
- `title`
- `description` (optional)
- `level`
- `topic_ids` (optional)

**Response**
- created learning outcome object

**Authorization**
- Instructor only  
- Must own the target course

**Notes**
- Learning outcomes are course-scoped.
- Topic links are optional at creation time.
- Linked topics must belong to the same course hierarchy.

---

### `GET /courses/{course_id}/learning-outcomes`
List all learning outcomes for a course.

**Response**
- `course_id`
- `learning_outcomes`

**Authorization**
- Instructor owner or authorized student context, depending on course access logic

**Notes**
- Returns learning-outcome records without requiring manual topic traversal on the client.

---

### `GET /courses/{course_id}/learning-outcomes/{learning_outcome_id}`
Get full details for a learning outcome.

**Response**
- learning outcome details
- related topics as `{id, title}`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Useful for details screens and editing workflows.

---

### `PATCH /courses/{course_id}/learning-outcomes/{learning_outcome_id}/update`
Update an existing learning outcome.

**Request**
- partial update fields for the learning outcome
- optional topic relation updates

**Response**
- updated learning outcome object

**Authorization**
- Instructor only  
- Must own the target course

**Notes**
- Course hierarchy and topic linkage are revalidated during update.

---

### `DELETE /courses/{course_id}/learning-outcomes/{learning_outcome_id}/delete`
Delete a learning outcome.

**Response**
- `204 No Content`

**Authorization**
- Instructor only  
- Must own the target course

**Notes**
- Related links are cleaned up before or during deletion according to service logic.

---

## 8. Modules

All module routes are nested under a course.

### `POST /courses/{course_id}/modules`
Create a module under a course.

**Request**
- `title`
- `description` (optional)
- `is_published` (optional)

**Response**
- created module object

**Authorization**
- Instructor only  
- Must own the target course

**Notes**
- Modules are ordered entities inside a course.
- If publication state is omitted, the backend decides the default.

---

### `PATCH /courses/{course_id}/modules/{module_id}/update`
Update a module.

**Request**
- `title` (optional)
- `description` (optional)
- `is_published` (optional)

**Response**
- updated module object

**Authorization**
- Instructor only  
- Must own the course and module hierarchy

**Notes**
- Partial updates are supported.

---

### `POST /courses/{course_id}/modules/{module_id}/copy`
Copy a module into another course owned by the same instructor.

**Request**
- handled according to service logic and route context

**Response**
- copied module object

**Authorization**
- Instructor only  
- Ownership checks apply to both source and target course context

**Notes**
- Designed for content reuse across the instructor’s own courses.
- Copy behavior may include module-related children depending on service implementation.

---

### `PATCH /courses/{course_id}/modules/reorder`
Reorder modules inside a course.

**Request**
- `module_ids` (final ordered list)

**Response**
- `course_id`
- `module_ids`

**Authorization**
- Instructor only  
- Must own the course

**Notes**
- Expects the final full ordering, not a partial move instruction.

**Example**
```json
{
  "module_ids": [10, 12, 11]
}
```

---

### `GET /courses/{course_id}/modules`
List modules for a course.

**Response**
- `course_id`
- `modules`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Modules are returned with ordering and publish-state information.

---

### `DELETE /courses/{course_id}/modules/{module_id}/delete`
Delete a module.

**Response**
- `204 No Content`

**Authorization**
- Instructor only  
- Must own the course

**Notes**
- Deletion behavior follows backend hierarchy and ownership validation.

---

## 9. Materials

Material endpoints mix nested and direct resource routes depending on the workflow stage.

### `POST /materials/courses/{course_id}/modules/{module_id}/materials/init-upload`
Initialize a material upload.

**Request**
- `filename`
- `content_type`
- `file_size_bytes`
- `title` (optional)
- `description` (optional)

**Response**
- `material_id`
- `module_id`
- `course_id`
- `upload_url`
- `storage_key`
- `bucket`
- upload constraints and status metadata

**Authorization**
- Instructor only  
- Must own the course/module context

**Notes**
- This is the first stage of the upload workflow.
- The current schema is designed for PDF uploads.

**Example**
```json
{
  "filename": "lecture1.pdf",
  "content_type": "application/pdf",
  "file_size_bytes": 1048576,
  "title": "Lecture 1",
  "description": "Introduction material"
}
```

---

### `POST /materials/materials/{material_id}/confirm-upload`
Confirm that a material upload has completed successfully.

**Request**
- confirmation-style request handled by current service flow

**Response**
- material upload confirmation object
- may include signed download URL information

**Authorization**
- Instructor only  
- Must own the material hierarchy

**Notes**
- Finalizes backend-side material state after the storage upload succeeds.

---

### `GET /materials/courses/{course_id}/modules/{module_id}/materials`
List materials for a module.

**Response**
- `course_id`
- `module_id`
- `materials`

**Authorization**
- Instructor owner or enrolled student, depending on content access state

**Notes**
- Returned items include metadata such as:
  - title
  - description
  - type
  - status
  - file metadata
  - optional download URL

---

### `GET /materials/courses/{course_id}/modules/{module_id}/materials/{material_id}/download-url`
Generate a signed download URL for a material.

**Response**
- `course_id`
- `module_id`
- `material_id`
- `download_url`
- `expires_in_seconds`

**Authorization**
- Access depends on:
  - instructor ownership
  - or valid student enrollment and allowed material visibility

**Notes**
- The storage layer is private by default for course materials.
- The backend decides whether a download URL may be issued.

---

### `PATCH /materials/{material_id}/reassign`
Move a material to another module.

**Request**
- `target_module_id`

**Response**
- `id`
- `module_id`
- `storage_key`

**Authorization**
- Instructor only  
- Ownership and hierarchy checks apply to both source and target module

**Notes**
- Used to reorganize course structure without reuploading the file.

---

### `DELETE /materials/courses/{course_id}/modules/{module_id}/materials/{material_id}`
Delete a material.

**Response**
- `204 No Content`

**Authorization**
- Instructor only  
- Must own the course/module/material hierarchy

**Notes**
- Removes the material record and related storage object according to service logic.

---

## 10. Topics

Topic routes are nested under a course/module/material hierarchy.

### `POST /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics`
Create a topic under a material.

**Request**
- `title`
- `description` (optional)
- `parent_topic_id` (optional)
- `learning_outcome_ids` (optional)

**Response**
- created topic object

**Authorization**
- Instructor only  
- Must own the full course/module/material hierarchy

**Notes**
- A topic becomes a subtopic when `parent_topic_id` is provided.
- Learning outcomes linked here must belong to the same course.

---

### `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics`
List topics for a material.

**Response**
- `course_id`
- `module_id`
- `material_id`
- `topics`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Topics and subtopics are represented using the same entity model.
- Ordering is included through `order_index`.

---

### `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}`
Get full details for a topic.

**Response**
- topic details
- linked learning outcomes as `{id, title}`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Useful for topic detail screens and editing flows.

---

### `PATCH /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/update`
Update a topic.

**Request**
- `title` (optional)
- `description` (optional)
- `parent_topic_id` (optional)
- `learning_outcome_ids` (optional, full replacement semantics)

**Response**
- updated topic object

**Authorization**
- Instructor only  
- Must own the hierarchy

**Notes**
- Topic hierarchy and linked learning outcomes are revalidated during update.

---

### `PATCH /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/reorder`
Reorder topics within a material.

**Request**
- `topic_ids` (final ordered list)

**Response**
- `course_id`
- `module_id`
- `material_id`
- `topic_ids`

**Authorization**
- Instructor only  
- Must own the hierarchy

**Notes**
- Expects the final full ordered list of topics for that material.

**Example**
```json
{
  "topic_ids": [21, 24, 22, 23]
}
```

---

### `DELETE /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/delete`
Delete a topic.

**Response**
- `204 No Content`

**Authorization**
- Instructor only  
- Must own the hierarchy

**Notes**
- Topic deletion follows backend ownership and hierarchy checks.

---

## 11. Questions

The question domain is central to the course question bank.

### Route Prefix
Question routes are grouped under:

```text
/courses/{course_id}
```

This means all question retrieval and creation flows operate within an explicit course context.

---

### `POST /courses/{course_id}/questions`
Create a question under a course.

**Request**
- `topic_id`
- `question_text`
- `type`
- `difficulty`
- `explanation` (optional)
- `options` (optional, type-dependent)
- `expected_answer` (optional, type-dependent)
- `grading_rubric` (optional, type-dependent)

**Response**
- created question object including:
  - course and topic linkage
  - question metadata
  - grading-related fields
  - creation timestamps

**Authorization**
- Instructor only  
- Must own the target course and topic hierarchy

**Notes**
- Questions are linked directly to topics.
- The backend uses shared validation plus type-specific validation helpers.
- Current and planned question types include:
  - `multiple_choice`
  - `multi_select`
  - `true_false`
  - `short_answer`
  - `essay`

**Example**
```json
{
  "topic_id": 42,
  "question_text": "Which normal form removes transitive dependency?",
  "type": "multiple_choice",
  "difficulty": "medium",
  "options": [
    { "id": "A", "text": "1NF" },
    { "id": "B", "text": "2NF" },
    { "id": "C", "text": "3NF" },
    { "id": "D", "text": "BCNF" }
  ],
  "expected_answer": "C",
  "explanation": "3NF removes transitive dependency."
}
```

---

### `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/questions`
List questions for a topic.

**Response**
- `course_id`
- `topic_id`
- `questions`

**Authorization**
- Read access depends on valid course access context

**Notes**
- This is the most direct question listing scope.

---

### `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/questions`
List questions for a material.

**Response**
- `course_id`
- `module_id`
- `material_id`
- `questions`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Aggregates questions across topics under the target material.

---

### `GET /courses/{course_id}/modules/{module_id}/questions`
List questions for a module.

**Response**
- `course_id`
- `module_id`
- `questions`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Aggregates questions across the module’s material/topic hierarchy.

---

### `GET /courses/{course_id}/questions`
List all questions for a course.

**Response**
- `course_id`
- `questions`

**Authorization**
- Read access depends on valid course access context

**Notes**
- Provides course-level question bank retrieval.

---

### `GET /courses/{course_id}/questions/{question_id}`
Get full details for a single question.

**Response**
- question details
- topic info
- related learning outcomes
- type-specific fields such as options, expected answer, and grading rubric

**Authorization**
- Read access depends on valid course access context

**Notes**
- This is the main detailed retrieval endpoint for question editing and inspection.

---

### `PATCH /courses/{course_id}/questions/{question_id}/update`
Update an existing question in the course question bank.

**Request** (all fields optional)
- `topic_id`
- `question_text`
- `difficulty`
- `explanation`
- `options`
- `expected_answer`
- `grading_rubric`
- `tags`

**Response**
- full question object (same shape as `QuestionCreateResponse`)

**Authorization**
- Instructor — course owner only

**Notes**
- Follows the project-wide dynamic update pattern: `null` = ignore, whitespace-only string = clear, actual value = update.
- Each field is individually validated before update (e.g., a field that cannot logically be an empty string is rejected if whitespace is passed).
- `type` is not updatable after creation.

---

### `POST /courses/{course_id}/questions/ai-generate`
Request AI-assisted question generation for selected topics.

**Request**
- `topics`: list of `{ topic_id, question_configs: [{ type, difficulty, count }] }`

**Response**
- `status`
- `ai_processing_started`
- `message`

**Authorization**
- Instructor — course owner only

**Notes**
- This is an async operation. The response confirms that the AI request was dispatched, not that questions are ready.
- Generated questions are delivered via the `POST /ai/callback` endpoint under operation type `question_generation`.
- Generated questions are inserted with `source = ai_generated` and `approval_status = pending`.
- Multiple topic/config combinations can be submitted in a single request.

---

## 12. Exams

The exam system is organized under `/courses/{course_id}/exams`.
Instructor-facing endpoints are prefixed with `/instructor`.
Student-facing endpoints are prefixed with `/student`.

All instructor endpoints are ownership-restricted.
All student endpoints require active enrollment in the course.

---

### Exam Hierarchy

```
Course
└── Exam
    └── Section  (single question type per section)
        └── Questions (from course question bank)
```

Questions are stored by reference (ID only) until the exam is published. On publish, a full snapshot of question data is taken and frozen. After publish, question bank updates no longer affect the exam.

---

### `POST /courses/{course_id}/exams/instructor`
Create a new exam.

**Request**
- `title`
- `description` (optional)
- `instructions` (optional)
- `exam_type`
- `duration_minutes` (optional)
- `max_attempts` (default: 1)
- `passing_score` (optional)
- `shuffle_questions` (default: false)
- `shuffle_options` (default: false)
- `available_from` (optional)
- `available_to` (optional)
- `access_code` (optional)

**Response**
- full exam object including proctoring flags and security settings

**Authorization**
- Instructor — course owner only

---

### `PATCH /courses/{course_id}/exams/instructor/{exam_id}`
Update exam metadata.

**Request** (all fields optional, same fields as create)

**Response**
- full exam object

**Authorization**
- Instructor — course owner only

**Notes**
- Not available after the exam is published.

---

### `GET /courses/{course_id}/exams/instructor`
List all exams for a course.

**Response**
- `course_id`
- `total`
- `exams`: list of exam summary objects

**Authorization**
- Instructor — course owner only

---

### `GET /courses/{course_id}/exams/instructor/{exam_id}`
Get full exam details including all sections and their questions.

**Response**
- full exam object with nested `sections`, each section containing its `questions`
- questions returned live from question bank if exam is not yet published
- questions returned from snapshot if exam is published

**Authorization**
- Instructor — course owner only

---

### `POST /courses/{course_id}/exams/instructor/{exam_id}/publish`
Publish an exam and freeze a snapshot of all question data.

**Response**
- `exam_id`
- `course_id`
- `is_published`
- `total_questions`
- `total_score`
- `message`

**Authorization**
- Instructor — course owner only

**Notes**
- After publishing, exam structure and question content are frozen.
- Students can only attempt published exams.
- Exam metadata and questions cannot be modified after publish.

---

### `POST /courses/{course_id}/exams/instructor/{exam_id}/sections`
Add a section to an exam.

**Request**
- `title`
- `description` (optional)
- `question_type`
- `time_limit_minutes` (optional)
- `must_complete` (default: true)

**Response**
- section object: `{ id, exam_id, title, description, question_type, order_index, question_count, section_score, time_limit_minutes, must_complete, created_at, updated_at }`

**Authorization**
- Instructor — course owner only

**Notes**
- Each section holds questions of a single type only, enforced by `question_type`.

---

### `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/reorder`
Reorder sections within an exam.

**Request**
- `section_ids`: ordered list of section IDs

**Response**
- `exam_id`, `course_id`, `section_ids`, `message`

**Authorization**
- Instructor — course owner only

---

### `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}`
Update a section.

**Request** (all fields optional)
- `title`
- `description`
- `question_type`
- `time_limit_minutes`
- `must_complete`

**Response**
- section object

**Authorization**
- Instructor — course owner only

---

### `DELETE /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}`
Delete a section and its associated question references.

**Response**
- `exam_id`, `course_id`, `deleted_section_id`, `message`

**Authorization**
- Instructor — course owner only

---

### `POST /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions`
Add questions from the course question bank to a section.

**Request**
- `question_ids`: list of question IDs

**Response**
- `exam_id`, `course_id`, `section_id`, `added_count`, `section_question_count`, `section_score`, `exam_total_questions`, `exam_total_score`
- `questions`: list of exam question items

**Authorization**
- Instructor — course owner only

**Notes**
- Questions must belong to the same course and match the section's `question_type`.
- Questions are stored by reference only until publish.

---

### `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions/reorder`
Reorder questions within a section.

**Request**
- `exam_question_ids`: ordered list of exam-question link IDs

**Response**
- `exam_id`, `course_id`, `section_id`, `exam_question_ids`, `message`

**Authorization**
- Instructor — course owner only

---

### `DELETE /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions/{exam_question_id}`
Remove a question from a section.

**Response**
- `exam_id`, `course_id`, `section_id`, `removed_exam_question_id`, updated counts and scores, `message`

**Authorization**
- Instructor — course owner only

---

### `GET /courses/{course_id}/exams/instructor/{exam_id}/export/pdf`
Export a published exam as a PDF file.

**Query Parameters** (all boolean, all optional with defaults)
- `include_learnova_logo` (default: true)
- `include_course_title` (default: true)
- `include_course_code` (default: false)
- `include_exam_metadata` (default: true)
- `include_instructions` (default: true)
- `include_section_descriptions` (default: true)
- `include_points` (default: true)
- `include_student_info_fields` (default: true)
- `include_answer_space` (default: true)
- `include_ocr_support` (default: false)
- `shuffle_questions` (optional override)
- `shuffle_options` (optional override)

**Response**
- PDF file stream

**Authorization**
- Instructor — course owner only

**Notes**
- `include_ocr_support` switches to an OCR-compatible PDF format for scanned answer sheet workflows.

---

### Exam Templates

Templates define a reusable exam structure (metadata + sections with question counts and point values). When a course is created, 4 default templates are automatically generated.

---

### `GET /courses/{course_id}/exams/instructor/templates`
List all exam templates for a course.

**Response**
- `course_id`, `total`
- `templates`: list of `{ id, name, exam_type, is_default, duration_minutes, total_questions, total_score, sections_count }`

**Authorization**
- Instructor — course owner only

---

### `GET /courses/{course_id}/exams/instructor/templates/{template_id}`
Get full template details including sections.

**Response**
- full template object with `sections`: `[ { id, template_id, title, question_type, question_count, points_per_question, section_score, order_index, ... } ]`

**Authorization**
- Instructor — course owner only

---

### `POST /courses/{course_id}/exams/instructor/templates`
Create a new exam template.

**Request**
- `name`
- `exam_type`
- `duration_minutes` (optional)
- `max_attempts` (default: 1)
- `passing_score` (optional)
- `shuffle_questions` (default: true)
- `shuffle_options` (default: true)

**Response**
- full template object

**Authorization**
- Instructor — course owner only

---

### `PATCH /courses/{course_id}/exams/instructor/templates/{template_id}`
Update template metadata.

**Request** (all fields optional, same as create)

**Response**
- full template object

**Authorization**
- Instructor — course owner only

---

### `DELETE /courses/{course_id}/exams/instructor/templates/{template_id}`
Delete an exam template.

**Response**
- `course_id`, `deleted_template_id`, `message`

**Authorization**
- Instructor — course owner only

---

### `POST /courses/{course_id}/exams/instructor/templates/{template_id}/sections`
Add a section to a template.

**Request**
- `title`
- `question_type`
- `question_count`
- `points_per_question`

**Response**
- `{ id, template_id, title, question_type, question_count, points_per_question, section_score, order_index, created_at, updated_at }`

**Authorization**
- Instructor — course owner only

---

### `PATCH /courses/{course_id}/exams/instructor/templates/{template_id}/sections/{section_id}`
Update a template section.

**Request** (all fields optional)
- `title`, `question_type`, `question_count`, `points_per_question`

**Response**
- section object

**Authorization**
- Instructor — course owner only

---

### `DELETE /courses/{course_id}/exams/instructor/templates/{template_id}/sections/{section_id}`
Delete a template section.

**Response**
- `course_id`, `template_id`, `deleted_section_id`, `total_questions`, `total_score`, `message`

**Authorization**
- Instructor — course owner only

---

### `POST /courses/{course_id}/exams/instructor/templates/{template_id}/generate-exam`
Generate a fully populated exam from a template with randomly selected questions.

**Request**
- `title`
- `topic_ids` (optional — filter source questions by specific topics)
- `section_difficulty_distribution` (optional — map of section index to difficulty level)

**Response**
- full exam object with all sections and questions already populated
- `{ id, course_id, title, exam_type, is_published, duration_minutes, max_attempts, shuffle_questions, shuffle_options, total_questions, total_score, created_at, updated_at, sections: [ { ..., questions: [...] } ] }`

**Authorization**
- Instructor — course owner only

**Notes**
- Questions are selected randomly per section from the course question bank, filtered by `question_type` and optionally `difficulty` and `topic_ids`.
- Each generation call may produce a different question set.
- The generated exam is created in draft state and must be published separately.

---

### Student Exam Endpoints

---

### `GET /courses/{course_id}/exams/student/exams`
List all published exams available to the current student in this course.

**Response**
- `course_id`, `total`
- `exams`: list of `{ id, title, description, exam_type, duration_minutes, max_attempts, passing_score, total_questions, total_score, available_from, available_to, is_available }`

**Authorization**
- Student — enrolled in course

---

### `POST /courses/{course_id}/exams/student/exams/{exam_id}/attempt`
Start a new exam attempt.

**Response**
- `{ exam_id, attempt_id, attempt_number, status, started_at, expires_at, title, description, instructions, exam_type, duration_minutes, total_questions, total_score, shuffle_questions, shuffle_options, proctoring flags, sections: [ { ..., questions: [...] } ] }`

**Authorization**
- Student — enrolled in course

**Notes**
- Returns the full exam structure with questions for the student to answer.
- `expires_at` is set based on `duration_minutes` if defined.
- Respects `max_attempts` — rejected if the student has exhausted attempts.

---

### `PUT /courses/{course_id}/exams/student/exams/{exam_id}/attempts/{attempt_id}/answers`
Save or update a single answer during an active attempt.

**Request**
- `exam_question_id`
- `selected_option_index` (optional — for single-choice questions)
- `selected_option_indices` (optional — for multi-choice questions)
- `answer_text` (optional — for essay/short-answer questions)
- `time_taken_seconds` (optional)

**Response**
- `attempt_id`, `exam_question_id`, `saved`

**Authorization**
- Student — owner of the attempt

**Notes**
- Designed for incremental answer saving during the attempt (e.g., auto-save or recovery from disconnection).
- Can be called multiple times for the same question — last write wins.

---

### `POST /courses/{course_id}/exams/student/exams/{exam_id}/attempts/{attempt_id}/submit`
Submit an exam attempt for grading.

**Request**
- `answers` (optional — final batch of answers to save before submission)
- `time_spent_seconds` (optional)

**Response**
- `{ attempt_id, exam_id, status, total_score, percentage_score, is_passed, correct_count, incorrect_count, unanswered_count, submitted_at }`

**Authorization**
- Student — owner of the attempt

**Notes**
- Auto-gradable questions (MCQ, true/false) are graded immediately.
- Essay and short-answer questions are sent to the AI service for grading. Results are delivered asynchronously via `POST /ai/callback` under operation type `exam_grading`.
- The response reflects partial results at submission time. Use `get_exam_attempt_result` to check final grading status via the `is_fully_graded` flag.

---

### `GET /courses/{course_id}/exams/{exam_id}/attempts`
List all completed or submitted attempts for this exam by the current student.

**Response**
- `exam_id`
- `attempts`: list of `{ attempt_id, attempt_number, status, started_at, submitted_at, graded_at, total_score, earned_score, percentage_score, is_passed }`

**Authorization**
- Student — enrolled in course

---

### `GET /courses/{course_id}/exams/{exam_id}/attempt/{attempt_id}/result`
Get the full graded result of a specific attempt.

**Response**
- `{ exam_id, attempt_id, attempt_number, status, is_fully_graded, started_at, submitted_at, graded_at, time_spent_seconds, total_score, earned_score, percentage_score, is_passed, correct_count, incorrect_count, unanswered_count, sections: [ { ..., questions: [ { ..., student_answer, correct_answer, is_correct, points_earned, teacher_feedback } ] } ] }`

**Authorization**
- Student — owner of the attempt

**Notes**
- `is_fully_graded` is `false` when AI grading for essay/short-answer questions is still pending.
- Partial results are returned immediately — auto-graded questions show their results even before AI grading completes.

---

## 13. AI Chat

The AI chat domain provides a RAG-powered conversational study assistant scoped to a specific course. All endpoints are student-facing and require active enrollment.

Responses are delivered asynchronously: the student sends a message, the backend forwards it to the AI service, and the AI response is delivered via `POST /ai/callback` under operation type `rag_response`. The student polls for the response using the SSE stream endpoint.

---

### `POST /courses/{course_id}/ai-chat/sessions`
Create a new chat session and send the first message.

**Request**
- `content` (1–2000 characters)

**Response**
- `session`: `{ id, course_id, session_title, is_active, started_at, last_message_at }`
- `message`: `{ id, session_id, message_type, content, sources, created_at }`

**Authorization**
- Student — enrolled in course

**Notes**
- Session title is automatically derived from the first 50 characters of the message content.
- The returned `message` represents the student's own message. The AI response is delivered asynchronously via the stream endpoint.

---

### `GET /courses/{course_id}/ai-chat/sessions`
List all chat sessions for the current student in this course.

**Response**
- `course_id`, `total`
- `sessions`: list of `{ id, course_id, session_title, is_active, started_at, last_message_at }`

**Authorization**
- Student — enrolled in course

---

### `GET /courses/{course_id}/ai-chat/sessions/{session_id}`
Get full session history including all messages.

**Response**
- `{ id, course_id, context_type, session_title, is_active, started_at, last_message_at, messages: [ { id, session_id, message_type, content, sources, created_at } ] }`

**Authorization**
- Student — owner of the session

**Notes**
- `sources` contains references used by the RAG system: `[ { title, page } ]`

---

### `POST /courses/{course_id}/ai-chat/sessions/{session_id}/messages`
Send a follow-up message in an existing session.

**Request**
- `content` (1–2000 characters)

**Response**
- `{ id, session_id, message_type, content, sources, created_at }`

**Authorization**
- Student — owner of the session

**Notes**
- The message is stored and forwarded to the AI service immediately.
- The AI response arrives asynchronously. Use the stream endpoint to receive it.

---

### `GET /courses/{course_id}/ai-chat/sessions/{session_id}/messages/{message_id}/stream`
Stream the AI response for a specific message using Server-Sent Events (SSE).

**Response**
- SSE stream — delivers the AI response event when it becomes available

**Authorization**
- Student — owner of the session

**Notes**
- The frontend should call this endpoint immediately after sending a message and hold the connection open.
- The event is fired once the AI callback is received and the response is persisted.
- This endpoint uses SSE (not WebSocket). The frontend must use `fetch` with `ReadableStream` rather than `EventSource` due to `Authorization` header requirements.
- The SQLAlchemy session is closed before the SSE stream starts to avoid holding a DB connection during the wait.

---

## 14. Settings

These endpoints manage the authenticated user’s profile, account security, avatar workflow, and preferences.

### `PATCH /settings/profile`
Update the current user’s profile.

**Request**
- `full_name` (optional)
- `avatar_url` (optional)
- `phone` (optional)
- `bio` (optional)
- `language_preference` (optional)

**Response**
- updated profile object

**Authorization**
- Authenticated user

**Notes**
- Profile updates are self-service and apply only to the current user.

---

### `POST /settings/avatar/upload-url`
Request a signed upload URL for avatar upload.

**Request**
- `content_type`
- `file_size_bytes` (optional)

**Response**
- `upload_url`
- `path`
- `token`
- `content_type`
- `max_bytes`

**Authorization**
- Authenticated user

**Notes**
- Intended for avatar uploads only.
- The allowed content types are image-oriented.

---

### `POST /settings/avatar/confirm`
Confirm avatar upload completion.

**Request**
- confirmation payload

**Response**
- `avatar_url`

**Authorization**
- Authenticated user

**Notes**
- Finalizes the avatar update flow after the client uploads the file.

---

### `PATCH /settings/password`
Change the current user’s password.

**Request**
- `current_password`
- `new_password`

**Response**
- `message`
- optional email notification result

**Authorization**
- Authenticated user

**Notes**
- Password change has security side effects, including token validity changes.

---

### `POST /settings/delete/request`
Request account deletion.

**Request**
- `current_password`

**Response**
- `message`
- optional email notification result

**Authorization**
- Authenticated user

**Notes**
- This starts a two-step delete-account workflow.

---

### `DELETE /settings/delete/confirm`
Confirm account deletion using OTP.

**Request**
- `otp`

**Response**
- `message`

**Authorization**
- Authenticated user with valid delete workflow context

**Notes**
- Account deletion is intentionally protected by both password confirmation and OTP confirmation.

---

### `GET /settings/preferences`
Get the current user’s preferences.

**Response**
- preference object including:
  - notification toggles
  - theme mode
  - profile visibility
  - online status visibility

**Authorization**
- Authenticated user

**Notes**
- Returns defaults if no stored preference row exists.

---

### `PATCH /settings/preferences`
Update the current user’s preferences.

**Request**
- notification flags
- `theme_mode`
- `profile_visibility`
- `show_online_status`

**Response**
- updated preferences object

**Authorization**
- Authenticated user

**Notes**
- Behaves like an upsert from the client perspective.

---

## 15. Organizations

These endpoints exist in the current backend but are not part of the main mature product flow yet.

### `POST /organizations`
Create an organization.

**Request**
- `name`
- `description`
- `logo_url` (optional)

**Response**
- created organization object

**Authorization**
- Authenticated user with appropriate role/context

**Notes**
- Organization workflows are currently best treated as early-stage or demo-oriented.

---

### `GET /organizations/{organization_id}/join-requests`
List join requests for an organization.

**Query Parameters**
- `view` (`pending` or `accepted`)

**Response**
- `count`
- `users`

**Authorization**
- Owner-oriented organization access

**Notes**
- Supports basic review of organization membership requests.

---

### `PATCH /organizations/{organization_id}/members/{org_member_id}/status`
Update an organization member’s status.

**Request**
- `new_status`

**Response**
- membership status update result

**Authorization**
- Owner-oriented organization access

**Notes**
- Intended for organization membership moderation.

---

## 16. AI Integration (Internal / Callback)

### `POST /ai/callback`
Receive an asynchronous callback from the AI service after backend-initiated AI processing completes.

**Request**
- signed JSON callback request using the shared AI integration protocol
- includes operation metadata and operation-specific `body`

**Response**
- callback handling result
- may include basic acknowledgment or operation summary according to current service behavior

**Authorization**
- Internal service-to-service endpoint  
- Uses signed request verification rather than JWT-based user authentication

**Notes**
- Callback authenticity is verified before the request enters business logic.
- Callback handling is dispatched based on `operation_type`.
- The currently supported callback-driven operations are:

- `content_structure_generation` — extracts topics, subtopics, and learning outcomes from uploaded materials
- `question_generation` — inserts AI-generated questions into the course question bank under the questions domain
- `exam_grading` — delivers grading results for essay and short-answer questions from a submitted exam attempt
- `rag_chat` — delivers the AI assistant's reply for a student chat message in the AI chat domain

- This endpoint is part of the backend's internal AI integration flow rather than the normal frontend-facing API surface.

---

## 17. Endpoint Summary by Feature

### Authentication
- `POST /auth/register`
- `POST /auth/send-verification-email`
- `GET /auth/verify-email`
- `POST /auth/check-email-verified`
- `POST /auth/login`
- `GET /auth/me`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/forgot-password`
- `POST /auth/reset-password`

### Courses
- `POST /courses`
- `POST /courses/{course_id}/invitations/upload`
- `POST /courses/{course_id}/invitations/send`
- `POST /courses/invitations/accept`
- `GET /courses/my`
- `GET /courses/{course_id}/invitations`
- `PATCH /courses/{course_id}`
- `POST /courses/{course_id}/publish`
- `POST /courses/{course_id}/cover/initiate`
- `POST /courses/{course_id}/cover/confirm`
- `POST /courses/{course_id}/enroll`
- `GET /courses/{course_id}/enrollment-requests`
- `PATCH /courses/{course_id}/enrollment-requests/{enrollment_id}`
- `GET /courses/search`
- `GET /courses/search/autocomplete`

### Learning Outcomes
- `POST /courses/{course_id}/learning-outcomes`
- `GET /courses/{course_id}/learning-outcomes`
- `GET /courses/{course_id}/learning-outcomes/{learning_outcome_id}`
- `PATCH /courses/{course_id}/learning-outcomes/{learning_outcome_id}/update`
- `DELETE /courses/{course_id}/learning-outcomes/{learning_outcome_id}/delete`

### Modules
- `POST /courses/{course_id}/modules`
- `PATCH /courses/{course_id}/modules/{module_id}/update`
- `POST /courses/{course_id}/modules/{module_id}/copy`
- `PATCH /courses/{course_id}/modules/reorder`
- `GET /courses/{course_id}/modules`
- `DELETE /courses/{course_id}/modules/{module_id}/delete`

### Materials
- `POST /materials/courses/{course_id}/modules/{module_id}/materials/init-upload`
- `POST /materials/materials/{material_id}/confirm-upload`
- `GET /materials/courses/{course_id}/modules/{module_id}/materials`
- `GET /materials/courses/{course_id}/modules/{module_id}/materials/{material_id}/download-url`
- `PATCH /materials/{material_id}/reassign`
- `DELETE /materials/courses/{course_id}/modules/{module_id}/materials/{material_id}`

### Topics
- `POST /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics`
- `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics`
- `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}`
- `PATCH /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/update`
- `PATCH /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/reorder`
- `DELETE /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/delete`

### Questions
- `POST /courses/{course_id}/questions`
- `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/topics/{topic_id}/questions`
- `GET /courses/{course_id}/modules/{module_id}/materials/{material_id}/questions`
- `GET /courses/{course_id}/modules/{module_id}/questions`
- `GET /courses/{course_id}/questions`
- `GET /courses/{course_id}/questions/{question_id}`
- `PATCH /courses/{course_id}/questions/{question_id}/update`
- `POST /courses/{course_id}/questions/ai-generate`

### Exams
- `POST /courses/{course_id}/exams/instructor`
- `PATCH /courses/{course_id}/exams/instructor/{exam_id}`
- `GET /courses/{course_id}/exams/instructor`
- `GET /courses/{course_id}/exams/instructor/{exam_id}`
- `POST /courses/{course_id}/exams/instructor/{exam_id}/publish`
- `POST /courses/{course_id}/exams/instructor/{exam_id}/sections`
- `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/reorder`
- `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}`
- `DELETE /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}`
- `POST /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions`
- `PATCH /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions/reorder`
- `DELETE /courses/{course_id}/exams/instructor/{exam_id}/sections/{section_id}/questions/{exam_question_id}`
- `GET /courses/{course_id}/exams/instructor/{exam_id}/export/pdf`
- `GET /courses/{course_id}/exams/instructor/templates`
- `GET /courses/{course_id}/exams/instructor/templates/{template_id}`
- `POST /courses/{course_id}/exams/instructor/templates`
- `PATCH /courses/{course_id}/exams/instructor/templates/{template_id}`
- `DELETE /courses/{course_id}/exams/instructor/templates/{template_id}`
- `POST /courses/{course_id}/exams/instructor/templates/{template_id}/sections`
- `PATCH /courses/{course_id}/exams/instructor/templates/{template_id}/sections/{section_id}`
- `DELETE /courses/{course_id}/exams/instructor/templates/{template_id}/sections/{section_id}`
- `POST /courses/{course_id}/exams/instructor/templates/{template_id}/generate-exam`
- `GET /courses/{course_id}/exams/student/exams`
- `POST /courses/{course_id}/exams/student/exams/{exam_id}/attempt`
- `PUT /courses/{course_id}/exams/student/exams/{exam_id}/attempts/{attempt_id}/answers`
- `POST /courses/{course_id}/exams/student/exams/{exam_id}/attempts/{attempt_id}/submit`
- `GET /courses/{course_id}/exams/{exam_id}/attempts`
- `GET /courses/{course_id}/exams/{exam_id}/attempt/{attempt_id}/result`

### AI Chat
- `POST /courses/{course_id}/ai-chat/sessions`
- `GET /courses/{course_id}/ai-chat/sessions`
- `GET /courses/{course_id}/ai-chat/sessions/{session_id}`
- `POST /courses/{course_id}/ai-chat/sessions/{session_id}/messages`
- `GET /courses/{course_id}/ai-chat/sessions/{session_id}/messages/{message_id}/stream`

### Settings
- `PATCH /settings/profile`
- `POST /settings/avatar/upload-url`
- `POST /settings/avatar/confirm`
- `PATCH /settings/password`
- `POST /settings/delete/request`
- `DELETE /settings/delete/confirm`
- `GET /settings/preferences`
- `PATCH /settings/preferences`

### Organizations
- `POST /organizations`
- `GET /organizations/{organization_id}/join-requests`
- `PATCH /organizations/{organization_id}/members/{org_member_id}/status`

---

## 16. Final Notes


### AI Integration Note

Learnova now includes implemented internal AI integration support for both outbound backend-to-AI requests and inbound callback handling.

This includes:
- backend-to-AI transport layer
- request signing and verification
- asynchronous callback reception through `POST /ai/callback`
- request tracking and lifecycle handling
- callback dispatch by `operation_type`

These components are documented in the backend architecture documentation. Only the callback endpoint appears here because it is part of the implemented backend API surface, while the rest remains internal integration infrastructure rather than normal frontend-facing API functionality.

This API reference reflects the current implemented backend routes and public request/response contracts visible in the codebase at the time of writing.

As the platform continues to evolve, the areas most likely to expand are:

- AI-assisted material extraction flows
- question generation support
- learner-facing workflows
- assessment and exam construction
- organization-based operational flows

When updating this document, the most important rule is to keep it aligned with the actual route and schema contract rather than aspirational design.