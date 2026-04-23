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

## 12. Settings

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

## 13. Organizations

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

## 14. AI Integration (Internal / Callback)

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
- The currently supported callback-driven operation is:
  - `content_structure_generation`
- This endpoint is part of the backend's internal AI integration flow rather than the normal frontend-facing API surface.

---

## 15. Endpoint Summary by Feature

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
