# Learnova - Backend Architecture

## 1. Overview

The Learnova backend is the central authority for application data, business rules, authorization, storage access, and feature orchestration.

It is built to support an AI-enhanced learning platform where instructors can create and structure courses, manage materials, topics, learning outcomes, and question banks, while the system progressively evolves toward AI-assisted learner support and organization-based educational workflows.

At the current stage, the backend is primarily optimized around instructor-driven content authoring and access control, while also establishing the foundations required for learner-facing features, AI integrations, and future assessment workflows.

---

## 2. Architectural Goals

The backend is designed around a set of practical engineering goals:

- **Keep the backend as the single source of truth**
- **Centralize business logic in services**
- **Enforce authorization through backend-controlled rules**
- **Preserve clear boundaries between features**
- **Protect private resources through signed storage access**
- **Support incremental feature growth without major rewrites**
- **Prepare the system for AI-assisted workflows without giving AI ownership of core state**

These goals shape both the structure of the codebase and the behavior of the implemented APIs.

---

## 3. Technology Stack

The backend is built with the following main technologies and infrastructure choices:

- **FastAPI** for the API application, routing, and dependency injection
- **PostgreSQL** as the primary relational database
- **SQLAlchemy Session** for database session management
- **Explicit SQL queries using `sqlalchemy.text(...)`** for feature-level data access
- **Pydantic** for request and response schemas
- **JWT** for access token authentication
- **Refresh-token cookie flow** for session continuity
- **Supabase Storage** for file storage, signed upload URLs, and signed download URLs
- **SMTP-based email delivery** for verification, password reset, invitations, and OTP flows
- **openpyxl** for invitation Excel parsing

The current implementation intentionally favors explicit service-driven logic and direct SQL control over heavy ORM-centric feature implementation.

---

## 4. High-Level System Responsibility

The backend currently handles the following major responsibilities:

- user registration and login
- email verification and password reset
- access token refresh and logout
- user profile and account settings management
- avatar upload flows
- secure account deletion confirmation
- course creation and ownership
- controlled invitation-based course access
- module management and module reuse
- material upload, access, reassignment, and deletion
- topic and subtopic management
- learning outcome management
- question creation and multi-scope question retrieval
- limited organization demo flows
- integration boundaries for future AI extraction and AI-assisted learning workflows
- course publishing and visibility-based access control
- course discovery through full-text search and autocomplete
- student-initiated course enrollment, including open and approval-based enrollment requests
- course cover image upload flows
- dynamic, partial updates to existing question bank entries
- AI-assisted question generation scoped to selected topics
- full exam authoring workflow: sections, question assignment, ordering, and publish-time snapshotting
- reusable exam templates with randomized exam generation
- exam PDF export, including an OCR-compatible export mode
- student exam attempt lifecycle: incremental answer saving, submission, and mixed automatic/AI-assisted grading
- a course-scoped, RAG-based AI study companion delivered through real-time chat sessions

---

## 5. Application Startup and Entry Point

The application entry point is centered around `main.py`, where environment variables are loaded before the rest of the app is imported, ensuring configuration is available early in the startup lifecycle.

The FastAPI app is initialized with CORS middleware and then composes the system by registering feature routers.

### Registered Feature Routers

The backend currently registers routers for:

- authentication
- courses
- learning outcomes
- modules
- materials
- topics
- questions
- exams
- ai_chat
- organizations
- settings
- ai

This confirms that the backend is assembled as a composition of domain routers rather than as one large monolithic route file.

### CORS Strategy

The current setup allows local frontend development origins, which supports local development and frontend-backend integration during active implementation.

---

## 6. Project Structure

The backend follows a modular structure organized around `app`, with shared infrastructure separated from domain features.

### High-Level Structure

```text
Backend/
├── alembic/
│  ├── versions/
│  └── env.py
├── app/
│  ├── core/
│  ├── db/
│  ├── domains/
│  ├── models/
│  └── main.py
├── assets/
├── alembic.ini
├── README.md
└── requirements.txt
```

### Main Application Packages

#### `app/core/`
Contains shared infrastructure and cross-cutting backend utilities such as:

- configuration
- dependency injection
- email sending
- Excel parsing
- JWT helpers
- password hashing and token signing helpers
- Supabase client setup
- storage helper functions
- token-store utilities

#### `app/db/`
Contains database session setup and database base wiring.

#### `app/domains/`
Contains the actual business domains of the application.

#### `app/models/`
Reserved for data models and structural database-related definitions.

---

## 7. Feature-Oriented Architecture

The backend is organized by feature domain. Each feature owns its API surface and business logic rather than relying on a globally shared service structure.

A typical feature package contains:

- `router.py`
- `schemas.py`
- `service.py`

These three files form the default backbone of a feature package.

Additional internal modules are used only when the feature flow requires them:

- `helpers.py` is used when reusable logic is needed across multiple endpoints or internal flows within the same feature.
- `handlers.py` is used when the feature is handler-driven by nature, or when one endpoint/service flow must dispatch between multiple entity variants, payload shapes, or operation types.

This keeps the default feature structure simple while still allowing justified internal expansion when the feature complexity actually demands it.

### Feature Packages

```text
domains/
├── ai/
├── ai_chat/
├── auth/
├── courses/
├── exams/
├── learningOutcomes/
├── materials/
├── modules/
├── organizations/
├── questions/
├── settings/
└── topics/
```

### Feature File Responsibilities

#### `router.py`
Defines:
- route prefixes
- endpoint paths
- status codes
- dependency injection
- request-to-service delegation

Routers remain intentionally thin.

#### `schemas.py`
Defines:
- request payload models
- response models
- validation contracts at the transport boundary

#### `service.py`
Contains:
- business rules
- authorization checks
- entity relationship validation
- SQL execution
- workflow orchestration
- transactional behavior
- response shaping

#### `helpers.py` (where applicable)
Used for reusable logic that does not belong directly in routing or core shared infrastructure.  
The questions feature uses helpers to support type-specific validation and extensibility.

#### `handlers.py` (where applicable)
Used when a feature needs operation-specific or variant-specific business handlers behind a shared orchestration flow.  
This is especially useful when one entrypoint must dispatch between multiple supported payload types or operation types while keeping the main service layer generic.

---

## 8. Core Architectural Principles

### 8.1 Backend as the Single Source of Truth

The backend does not trust the frontend to enforce critical business decisions.  
Instead, it validates:

- user identity
- system role
- course ownership
- enrollment state
- parent-child hierarchy correctness
- allowed state transitions
- token validity
- file upload and access rules

This keeps data integrity and authorization under backend control.

---

### 8.2 Thin Routers, Service-Centered Logic

Routers are primarily responsible for receiving the HTTP request and injecting shared dependencies.  
They delegate actual work to feature services.

This pattern keeps:
- transport logic in routers
- domain rules in services
- shared infrastructure in `core`

The result is cleaner feature boundaries and easier long-term maintenance.

---

### 8.3 Explicit Validation Layers

Validation is split across multiple layers:

- **Schema validation** through Pydantic
- **Business-rule validation** inside services
- **Database integrity validation** through relational constraints
- **Token validation** through shared core utilities

This layered validation approach reduces reliance on any single mechanism.

---

### 8.4 Explicit SQL Over Implicit ORM Flows

Feature services use direct SQL statements through `sqlalchemy.text(...)` and `Session.execute(...)`.

This gives the codebase:
- precise query control
- explicit joins and filters
- predictable SQL behavior
- easier feature-specific query shaping

The trade-off is that services take more responsibility for:
- consistency
- response shaping
- transaction safety

Within the current architecture, that trade-off is acceptable because service modules already act as the main business boundary.

---

## 9. Shared Core Layer

The `core` package provides the foundational utilities that make feature modules consistent.

### 9.1 Configuration

`config.py` centralizes environment-based settings, including:

- API and frontend base URLs
- JWT configuration
- invite-token secret
- SMTP configuration
- email branding values
- refresh-token cookie settings
- Supabase bucket configuration

It also adapts cookie behavior based on environment, including:

- `SameSite=lax` and `Secure=false` for development
- `SameSite=none` and `Secure=true` for production

This is an important detail because refresh-token cookie behavior changes significantly between local and production deployments.

---

### 9.2 Dependency Injection

`deps.py` provides the shared `get_current_user` dependency and token resolution flow.

This layer is responsible for:

- extracting the Bearer token
- decoding the access token
- loading the user from the database
- verifying email activation state
- checking token revocation by comparing `last_password_change`
- returning a normalized current-user object to downstream routes and services

This creates a consistent authenticated user context across all protected features.

---

### 9.3 JWT Utilities

`jwt.py` handles:

- access token creation
- access token decoding

Access tokens include:
- `sub`
- `iat`
- `exp`
- optional extra claims

JWT validation errors are translated into proper authentication failures instead of being silently ignored.

---

### 9.4 Security Utilities

`security.py` handles low-level security operations such as:

- password hashing
- password verification
- HMAC SHA-256 signing

Passwords are hashed using PBKDF2-HMAC-SHA256 with explicit salt and iteration handling, which keeps password verification fully backend-controlled.

---

### 9.5 Token Store Utilities

`token_store.py` provides reusable token validation helpers for one-time token flows.  
It verifies:

- token existence
- token type
- unused status
- expiration state

This supports flows such as:
- email verification
- password reset
- account deletion OTP
- other one-time secure actions

---

### 9.6 Storage Utilities

`storage_utils.py` provides shared storage-safe helpers such as:

- object key splitting
- filename sanitization
- storage deletion helpers

This is important because file handling is not left to raw user filenames or client-generated paths.

---

### 9.7 Excel Utilities

`excel_utils.py` supports invitation workflows by:

- reading uploaded `.xlsx` files
- detecting the email column
- validating rows
- normalizing emails
- deduplicating values
- returning structured extraction results

This enables controlled batch invitation preparation without exposing the core invitation logic to file-format complexity.

---

### 9.8 Email Infrastructure

`emailer.py` is part of the shared core layer and supports outbound email-based workflows across the system, including:

- verification emails
- password reset emails
- invitation emails
- OTP confirmation emails

This keeps email sending logic reusable instead of scattering it across features.

---

### 9.9 Supabase Client

The backend uses a shared Supabase client for storage-related operations.  
Feature services use it indirectly through controlled business flows rather than exposing storage operations directly to clients.


### 9.10 AI Service Integration Foundation

The `core` package now includes a reusable AI service integration foundation that standardizes how backend features communicate with external AI services.

This layer exists to prevent AI communication logic from being reimplemented separately inside feature services.  
Instead of allowing each feature to handle transport, signing, request formatting, and lifecycle tracking independently, the backend centralizes these concerns in shared core infrastructure.

This is architecturally important because AI communication is a cross-cutting system capability rather than a single-feature implementation detail.

### 9.11 AI Request Protocol

Backend-to-AI communication is structured around a unified request contract.

The request shape is intentionally divided into:

- **shared metadata at the root level**
- **feature-specific payload inside `body`**

This design allows the backend to keep transport-level and tracking-relevant fields consistently available across all AI workflows while still allowing each feature to provide its own domain-specific payload.

A key example is `course_id`, which is treated as root-level metadata rather than being nested inside `body`.  
This keeps important context available for tracking, authorization-aware orchestration, and future multi-feature reuse.

### 9.12 AI Transport Client

The core integration layer includes a dedicated outbound transport client responsible for communicating with the AI service.

Its responsibility is to handle:

- request envelope preparation
- target path routing
- request dispatch
- timeout-aware outbound communication
- consistent integration behavior across features

This means feature services should not directly own low-level AI HTTP communication behavior.  
They should prepare only the feature-specific request body and the intended AI endpoint path, while the shared transport layer handles the rest.

### 9.13 AI Signing and Verification Utilities

The AI integration foundation includes reusable signing and verification utilities built around HMAC-based request authentication.

These utilities are responsible for:

- deterministic request serialization inputs where needed
- request-body hashing
- signature generation for outbound backend requests
- callback signature verification for inbound AI responses

This logic belongs in shared infrastructure because request authenticity is an integration-level concern, not a feature-specific business rule.

### 9.14 AI Request Tracking Support

The backend also includes backend-specific request tracking support for AI operations.

This tracking layer is responsible for recording request lifecycle metadata such as:

- request identity
- operation type
- target endpoint
- request payload
- response payload
- status transitions
- timing information
- error state

This gives the backend operational visibility into asynchronous AI workflows and provides a consistent debugging and audit trail for future AI-enabled features.

### 9.15 Shared vs Backend-Only AI Integration Responsibilities

A deliberate architectural separation is maintained between:

- **shareable AI integration logic**
- **backend-only persistence and operational tracking logic**

The shareable side includes concerns such as:

- protocol shape
- signing rules
- verification behavior
- request/response contract expectations

The backend-only side includes concerns such as:

- database persistence
- request lifecycle logging
- internal correlation with backend entities
- operational observability

This separation is important because some integration rules are part of the backend-to-AI agreement, while others are implementation details specific to Learnova's backend.


---

## 10. Request Lifecycle

A typical request follows the same architectural path across the application:

1. **Router receives the request**
2. **FastAPI injects dependencies**
   - database session
   - current authenticated user
3. **Router delegates to a service function**
4. **Service validates domain rules**
5. **Service executes SQL and orchestrates the workflow**
6. **Service returns normalized response data**
7. **Router returns the HTTP response**

This design keeps request handling predictable and reusable across features.

---

## 11. Authentication and Session Architecture

The authentication layer combines JWT-based API access with refresh-token cookie rotation and token-backed email verification flows.

### 11.1 Authentication Flows

The backend currently supports:

- registration
- sending verification email
- email verification
- checking email verification status
- login
- current-user retrieval
- refresh token flow
- logout
- forgot password
- reset password

This provides a complete account-lifecycle foundation for the platform.

---

### 11.2 Access Tokens

Access tokens are short-lived JWTs used in API authorization headers.  
They carry the authenticated user identity and can include additional claims.

---

### 11.3 Refresh Tokens

Refresh tokens are stored in an HTTP-only cookie and are used to issue new access tokens without requiring repeated login.

This strategy improves user experience while preserving backend-controlled session renewal.

The cookie settings are environment-aware and are configured centrally through the settings layer.

---

### 11.4 Token Revocation by Password Change

The current-user dependency compares the token’s embedded `last_password_change` value against the database value.  
If they no longer match, the token is treated as revoked.

This is a practical way to invalidate previously issued tokens after password changes without requiring a fully centralized token blacklist for every access token.

---

### 11.5 Token-Based Email and Account Flows

The backend uses token records for flows that require explicit user confirmation, including:

- email verification
- password reset
- invitation acceptance
- account deletion OTP confirmation

This makes sensitive state transitions explicit and verifiable.

---

## 12. Authorization Model

Authorization in Learnova is not limited to role checks.  
It combines role, ownership, enrollment state, and content hierarchy validation.

### 12.1 Role-Based Access

The active system roles visible in the backend include:

- `instructor`
- `student`
- `owner`
- `assistant` (allowed during registration, though not currently central to the main product flow)

Examples:
- instructors create and manage instructional content
- students consume course content through enrollment-based access
- owners are used in organization-related demo workflows

---

### 12.2 Ownership-Based Authorization

Instructor-side write features are strongly ownership-based.

Examples:
- only the instructor who created the course can manage that course
- only the course owner can create, reorder, update, or delete modules
- only the course owner can manage materials, topics, learning outcomes, and questions tied to that course hierarchy

This keeps write privileges aligned with actual course ownership rather than generic role status alone.

---

### 12.3 Enrollment-Based Authorization

Student access to instructional content is enrollment-aware.

A student is typically allowed to read course content only if:
- they are enrolled in the relevant course
- and the enrollment status is valid for access

This protects course resources from unauthorized viewing while still supporting controlled academic access.

---

### 12.4 State-Aware Authorization

Authorization is also influenced by resource state in some features.

For example:
- students do not automatically see all material states
- instructors may see draft or internal states that students cannot
- token-backed flows require the correct token type and token state

This adds business-state validation on top of basic role checks.

---

## 13. Course-Centered Domain Model

The backend models educational content using a hierarchical structure centered around the course.

### 13.1 Core Hierarchy

```text
Course
├── Learning Outcomes
├── Modules
│   ├── Materials
│   │   ├── Topics
│   │   │   ├── Subtopics
│   │   │   └── Questions
```

### 13.2 Domain Semantics

#### Course
The top-level instructional entity.  
It defines the main ownership boundary and access model.

#### Learning Outcomes
Learning outcomes are course-scoped and linked to topics through a many-to-many relationship.

#### Module
Modules partition course content into ordered segments and support copy/reuse workflows.

#### Material
Materials are uploaded files attached to modules and are managed through controlled storage flows.

#### Topic
Topics are material-scoped content units that serve as the canonical anchor for question ownership.

#### Subtopic
Subtopics are represented as topics with a parent reference rather than as a separate entity type.

#### Question
Questions are linked directly to topics.  
Learning outcome relevance is inferred through topic-to-learning-outcome links.

This design keeps the hierarchy normalized and avoids redundant relationship duplication.

---

## 14. Course Architecture

The course feature is the root of the instructional side of the system.

### Current Responsibilities

- course creation
- course metadata update
- course publishing
- cover image upload (staged: initiate → confirm)
- invitation upload via Excel
- invitation sending
- invitation acceptance
- open and approval-based enrollment
- enrollment request listing and approval/decline
- listing current user's accessible courses
- listing course invitations
- full-text course search and autocomplete

### Architectural Importance

Courses establish:
- the main instructor ownership boundary
- the enrollment access model
- the root container for modules, materials, learning outcomes, topics, and questions

---

## 15. Course Visibility and Access Lifecycle
<!-- *(insert after Section 14, before the existing Section 15 "Invitation and Access Model")* -->

A course moves through a deliberate visibility lifecycle rather than being accessible by default.

### Draft State

A newly created course starts in `draft` status and is visible only to its owner. No visibility level, enrollment setting, or invitation can override this — publishing is a required, explicit transition before any other user can see the course in any form.

### Publishing and Visibility Levels

Publishing a course activates one of three visibility levels, each with a distinct access boundary:

- **`public`** — visible to everyone, included in search results
- **`unlisted`** — accessible only via direct link; excluded from search
- **`private`** — accessible only to the owner and enrolled users; not reachable by link or search

### Enrollment as a Separate Axis

Visibility controls *who can see the course exists*. Enrollment controls *who can access its content*. These are deliberately independent:

- `is_open_for_enrollment` determines whether enrollment is currently allowed, regardless of visibility
- `requires_enrollment_approval` determines whether enrollment is immediate or pending instructor approval
- enrollment is only possible on a published course

A user can be enrolled in a `private` course (via direct instructor action or a prior invitation) and retain full access even if the course's visibility never makes it independently discoverable.

### Pre-Enrollment Content Boundary

A non-enrolled user who reaches a course (via search, direct link, or invitation) sees a restricted view: course metadata, the module list, and learning outcomes — not full module/material content. This is implemented by making `list_modules` and `list_learning_outcomes` visibility-aware rather than gating access at the course level alone, allowing prospective students to evaluate a course before enrolling.

### Architectural Rationale

Separating visibility, enrollment permission, and content access into independent checks (rather than a single course-level flag) allows the same course entity to support open public courses, invite-only private cohorts, and link-shared unlisted courses without divergent code paths.

---

## 16. Course Search Architecture
*(insert after the new "Course Visibility and Access Lifecycle" section)*

Course discovery is implemented using PostgreSQL's native full-text search rather than an external search engine. This keeps search capability inside the system of record instead of introducing a separate infrastructure dependency and synchronization concern.

### Search Vector Column

The `courses` table carries a `search_vector` column of type `tsvector`, indexed with a GIN index for efficient text search at the current and expected scale.

### Weighted Ranking

The search vector is built from multiple course fields with weighted relevance:

- **Weight A (highest):** `title`
- **Weight B:** `category`
- **Weight C:** `description` and `tags` (aggregated)

This means a match on the course title ranks above a match found only in the description or tags.

### Trigger-Maintained Consistency

The `search_vector` column is kept in sync through a database trigger (`BEFORE INSERT OR UPDATE`) rather than being recomputed in application code. This guarantees the search index can never drift out of sync with course data, regardless of which service or code path performs the write — consistent with the backend's broader principle of keeping the database authoritative for derived state it can own directly.

### Search Scope

Search results are restricted to published, `public` courses, consistent with the visibility model — `private` and `unlisted` courses never appear in search regardless of relevance match.

### Autocomplete as a Separate Concern

Autocomplete suggestions are served by a lightweight, independent prefix-match query against course titles rather than reusing the full-text ranked search path. This keeps the type-ahead experience fast and simple, decoupled from the heavier weighted-relevance search used for actual search submissions.

---

## 17. Invitation and Access Model

A key design choice in Learnova is support for both open and controlled course access.

### 17.1 Supported Access Patterns

- **Open enrollment**
- **Invitation-based controlled enrollment**

### 17.2 Invitation Flow

For controlled access, instructors can:

- upload an Excel sheet containing student emails
- extract and validate email addresses
- store invitation records
- send invitation emails
- allow invited students to accept invitations through a token-backed endpoint

This is particularly important for real teaching scenarios where instructors want to restrict access to a known section or cohort.

---

## 18. Module Architecture

Modules are ordered child entities under a course.

### Supported Module Operations

- create
- update
- copy
- reorder
- list
- delete

### Architectural Significance

The module layer gives instructors a reusable structure for organizing a course.  
The copy operation is especially valuable because it allows an instructor to reuse module content across their own courses without rebuilding the structure manually.

Ordering is explicitly managed through backend-controlled reorder logic rather than being left implicit.

---

## 19. Material Architecture

Materials represent uploaded educational files under a module.

### Supported Material Operations

- initialize upload
- confirm upload
- list module materials
- generate download URL
- reassign material
- delete material
- internal copy/delete support in service logic

### Upload Strategy

Material uploads are designed as a staged workflow:

1. validate course/module ownership and metadata
2. create the material record
3. generate the storage target
4. upload the file through signed storage flow
5. confirm the upload after the object exists

This is safer than letting the client define storage state arbitrarily.

### Access Strategy

Material access is backend-controlled:
- instructors can access materials within their own courses
- students must be enrolled and allowed
- student visibility can depend on material status
- download access is provided through signed URLs instead of unrestricted direct bucket access

This reinforces the principle that storage access must remain subordinate to application rules.

### AI Processing Integration

Materials can optionally participate in an AI processing workflow after upload confirmation.

When `use_ai_processing = true`, the backend uses the confirm-upload flow to trigger an outbound AI request through the shared integration layer.  
The current operation used for this flow is `content_structure_generation`.

That outbound request remains transport- and security-controlled by shared infrastructure rather than by material-specific service code.  
The AI service then processes the material asynchronously and returns results through the generic callback endpoint.

After callback verification and dispatch, the backend persists the returned structured content and updates the material's AI-processing fields without conflating AI processing state with the material's general upload/status lifecycle.

---

## 20. Topic Architecture

Topics are material-scoped content units and are one of the most important structural entities in the backend.

### Supported Topic Operations

- create
- list by material
- get details
- update
- reorder
- delete

### Architectural Decisions

- topics and subtopics are represented using the same entity model
- hierarchy is expressed through `parent_topic_id`
- topics anchor both question ownership and learning-outcome mapping

This decision avoids maintaining separate topic and subtopic entity types while still preserving hierarchy.

---

## 21. Learning Outcome Architecture

Learning outcomes are course-scoped instructional goals linked to topics.

### Supported Learning Outcome Operations

- create
- list by course
- get details
- update
- delete

### Architectural Significance

This design separates:
- **course-level instructional intent** from
- **material-level content structure**

The many-to-many relationship between learning outcomes and topics allows the backend to connect instructional goals to specific parts of the course content without collapsing them into the same entity.

---

## 22. Question Architecture

The question domain is one of the most important backend areas because it directly supports the product’s question-bank identity.

### 22.1 Topic-Scoped Question Ownership

All questions are linked directly to a `topic_id`.

This is a deliberate architectural choice because:
- topics represent the most precise instructional content scope
- learning outcomes can still be inferred through topic relationships
- questions remain grounded in course content rather than floating independently

---

### 22.2 Unified Question Table Strategy

The backend uses a unified question model instead of separate tables for each question type.

This supports:
- centralized question management
- consistent retrieval
- simpler question-bank aggregation
- easier future assessment composition

---

### 22.3 Type-Aware Validation

Although persistence is unified, validation is type-aware.

The questions feature uses:
- shared question validation
- type-specific helper logic

This allows the system to support multiple question types while keeping endpoint flow consistent and extendable.

Supported and planned question types include:

- multiple choice
- multi-select
- true/false
- short answer
- essay

---

### 22.4 Multi-Scope Question Retrieval

The backend supports question retrieval across multiple scopes:

- by topic
- by material
- by module
- by course
- by question ID

Even though questions are directly topic-scoped, broader listing endpoints derive results through the hierarchy instead of duplicating ownership across entities.

---

### 22.5 Question Bank Foundation

At the product level, the implemented question domain forms the foundation of the **course question bank**.

This is strategically important because the next major workflow is assessment construction from approved questions, rather than building a disconnected exam system from scratch.

---

### 22.6 Dynamic Question Update

Question updates follow the same project-wide partial-update convention used elsewhere in the backend: a `null` field is ignored, a whitespace-only string clears the field, and an actual value updates it. Each field is validated individually before this rule is applied, since not every field can legitimately be cleared to empty (e.g. `question_text`).

The question's `type` is immutable after creation, since downstream exam sections enforce a single question type per section — allowing `type` to change post-creation could silently break exam section type constraints.

---

### 22.7 AI-Assisted Question Generation

Question generation reuses the same AI service integration foundation as material content-structure extraction (Section 9.10–9.15), rather than implementing separate transport, signing, or tracking logic.

A generation request is grouped per topic, with one or more `(type, difficulty, count)` configurations per topic, allowing an instructor to request a varied mix of question types and difficulty levels in a single call.

Generated questions are inserted with `source = ai_generated` and `approval_status = pending`, mirroring the same "suggested, not yet accepted" treatment already used for AI-generated topics and learning outcomes (Section 30.15). The AI layer proposes content; the backend and instructor remain the authority over what becomes accepted question-bank content.

---

## 23. Exam Architecture
*(insert after Section 20 — Question Architecture, as a new major section)*

The exam domain is the largest feature area in the backend and is built directly on top of the question bank rather than as a parallel, disconnected assessment system.

### Hierarchy

```text
Course
└── Exam
    └── Section  (single question type per section)
        └── Questions (referenced from the course question bank)
```

Each section enforces a single `question_type`. This keeps section-level behavior (timing, scoring, rendering) predictable and avoids mixed-type sections that would complicate both grading and PDF export logic.

### Reference-Until-Publish, Snapshot-at-Publish

While an exam is in draft state, its questions are stored as references (IDs) into the question bank only. When the exam is retrieved (e.g. `get_exam`), question content is read live from the question bank — meaning an instructor's edits to a question are reflected in any draft exam that references it.

When the exam is published, the backend takes a full snapshot of every question's current data and freezes it onto the exam. After publishing:

- the exam's question content can no longer be affected by later question bank edits
- the exam's structure (sections, questions, metadata) becomes immutable

This two-phase strategy gives instructors the flexibility to keep refining the question bank while drafting an exam, while guaranteeing that once an exam is live to students, its content is stable and auditable — a student's graded result will always correspond to the exact question wording and options they were shown.

### Exam Templates

Exam templates are a separate, parallel hierarchy that defines reusable exam *shape* without binding to actual question instances:

```text
Course
└── Exam Template
    └── Template Section  (question_type, question_count, points_per_question)
```

Template sections store counts and scoring parameters only — no question references. This keeps templates structurally simple and reusable across many generated exams.

Four default templates are automatically created whenever a course is created, giving every instructor a working starting point instead of an empty state. Default template values are backend-defined and applied through the existing `create_course` flow rather than as a separate provisioning step.

### Exam Generation from Template

`generate_exam_from_template` builds a fully populated exam from a template in a single operation: for each template section, questions are selected **randomly** from the course question bank, filtered by `question_type` and the requested difficulty for that section (and optionally constrained to specific topics).

Randomization is intentional and repeatable-by-design to be *non-repeatable*: each generation call can produce a different question set even from the same template and parameters. This supports practice-exam and repeated-attempt use cases where instructors want variation rather than a deterministic draw. The generated exam is created in draft state and still requires an explicit publish step — generation does not bypass the snapshot-at-publish safeguard.

### Grading Split: Automatic vs AI-Assisted

Exam submission triggers two parallel grading paths based on question type:

- **Auto-gradable types** (multiple choice, true/false) are graded synchronously at submission time, with no external dependency
- **Subjective types** (essay, short answer) are dispatched to the AI service through the same AI integration foundation used elsewhere in the backend, and graded asynchronously via the `exam_grading` callback operation

This split exists because objective question types have a deterministic correct answer that the backend can evaluate directly, while subjective answers require judgment that only the AI service (or a human reviewer, in the future) can reasonably provide.

### Partial Results and the `is_fully_graded` Flag

Because AI grading is asynchronous, the `submit_exam` response cannot wait for it without blocking the student. Instead, submission returns immediately with whatever results are available — auto-graded questions are scored right away, while AI-graded questions remain pending.

The `is_fully_graded` flag distinguishes a fully scored attempt from one still awaiting AI grading. The attempt-result endpoint is the canonical place to check final state once AI grading completes and is persisted via the callback handler. This favors availability of partial results over forcing the student (or frontend) to block on a synchronous, all-or-nothing grading response.

### PDF Export

Exam PDF export operates on the same snapshot data used by the live exam, and supports two structurally different output modes selected per request:

- a **standard** exam PDF
- an **OCR-compatible** PDF, designed for scanned answer-sheet workflows

Both modes accept the same set of per-request toggles (logo, course title/code, exam metadata, instructions, section descriptions, point values, student info fields, answer space) via query parameters, allowing the instructor to tailor the exported document without needing separate export endpoints per configuration.

---

## 24. Real-Time Communication Layer
<!-- *(insert after Section 9 — Shared Core Layer, as a new subsection 9.16, or as its own top-level section before Section 10)* -->

The backend includes a dedicated real-time communication layer in `app/core/event_bus/`, built on PostgreSQL's native `LISTEN`/`NOTIFY` mechanism.

### Why LISTEN/NOTIFY

`LISTEN`/`NOTIFY` was chosen over introducing Redis pub/sub or relying on database polling. This avoids adding a new infrastructure dependency purely for event delivery, and keeps the database as the single authoritative source for both application state and the notifications derived from it — consistent with the backend's broader "backend/database as source of truth" principle.

### Connection Pool Lifecycle

`connections.py` manages a dedicated `asyncpg` connection pool, separate from the main SQLAlchemy session machinery, initialized once at application startup (`init_event_bus`) and torn down at shutdown (`close_event_bus`). Feature code accesses the pool only through `get_pool()`, which raises explicitly if the pool was never initialized — preventing silent no-op behavior if startup wiring is missing.

### Dual Publish Paths

The layer exposes two publish functions:

- `publish(...)` — async, used from async request/service code, acquires a pooled `asyncpg` connection and issues `pg_notify`
- `publish_sync(...)` — synchronous, using a direct `psycopg` connection, used from contexts that are not async

`publish_sync` exists specifically because AI callback handlers (e.g. `exam_grading`, the RAG chat callback) run inside the backend's existing synchronous SQLAlchemy request/service flow. Rather than converting the entire callback chain to async to gain access to the event bus, a synchronous publish path lets those handlers notify listeners without changing the architecture of the callback feature.

### Subscribe as a Bounded, Single-Shot Wait

`subscribe(...)` is an async generator, but it is not a long-lived multiplexed subscription. Each call:

1. acquires a pooled connection and registers a listener callback for the given channel
2. waits on an `asyncio.Queue` for exactly one payload, bounded by a timeout (default 30s)
3. yields the received payload, or an empty string if the wait times out
4. always removes the listener and releases the connection back to the pool in a `finally` block, regardless of outcome

This bounded, single-shot design keeps connection pool usage predictable — each SSE wait holds exactly one pooled connection for at most the timeout duration, with guaranteed cleanup, rather than allowing long-lived or leaked listener connections to accumulate.

### Interaction with the SQLAlchemy Session

Endpoints that wait on `subscribe(...)` (the SSE stream endpoint) close their SQLAlchemy session before entering the wait. The event bus uses its own independent connection pool, so holding both a live ORM session and an open event-bus wait simultaneously would needlessly tie up two separate database connections for the duration of the wait.

### Shared Core Infrastructure, Not Feature-Local

Although currently consumed only by the AI chat domain, the event bus is implemented as shared `core` infrastructure rather than chat-specific code — the same architectural treatment already given to the AI service integration foundation (Section 9.10–9.15). This allows any future feature requiring real-time push behavior to reuse the same publish/subscribe primitives without reimplementing connection or lifecycle handling.

---

## 25. AI Chat / RAG Architecture
<!-- *(insert after the Exam Architecture section)* -->

The AI chat domain provides a course-scoped, RAG-based study companion. It is enrollment-gated like other student-facing course content.

### Session and Message Model

A chat session groups an ongoing conversation. The session title is automatically derived from the first 50 characters of the session's first message, removing the need for the student to manually name a session.

### Inverse Correlation Between AI Replies and User Messages

Rather than modeling a conversation as paired "exchange" rows or a separate join table, an AI-generated message stores a `user_message_id` pointing back to the specific user message it answers. A populated `user_message_id` is also how a message row is identified as an AI reply rather than a user message. This keeps the message table flat (one row per message, of either origin) while still preserving an explicit, queryable link between a question and its answer.

### Send Flow and AI Dispatch

Sending a message is a two-part action: the message is persisted immediately, then forwarded to the AI service through the same AI service integration foundation used by material processing and question generation (Section 9.10–9.15). The chat domain does not implement its own request signing, transport, or tracking logic — it reuses the shared integration layer like every other AI-driven feature.

### Asynchronous Response Delivery

The AI's reply does not return synchronously. It arrives later through the generic `POST /ai/callback` endpoint under operation type `rag_chat`, where a dedicated handler validates and persists it using the same registry-based dispatch pattern described in Section 30.6.

### Real-Time Delivery via Message-Scoped Channels

The frontend learns the AI has responded through the real-time communication layer (see "Real-Time Communication Layer" section), using a channel name derived from the **user's message ID**:

```python
# Frontend opens a stream scoped to the message it just sent:
async for payload in subscribe(channel=f"chat_{message_id}"):
    ...

# The rag_chat callback handler publishes once the reply is persisted:
publish_sync(channel=f"chat_{message_id}", payload="ready")
```

Channels are scoped to the message ID rather than the session ID so that each stream connection corresponds to exactly one pending AI reply. If a student sends a second message before the first reply arrives, each message's stream is independently scoped and cannot cross-talk with the other.

The publish payload itself is a lightweight "ready" signal rather than the message content — once the frontend receives it, it is expected to fetch the persisted message content through the regular session/message endpoints rather than receiving the AI response body directly over the SSE channel.

### Transport Choice: fetch + ReadableStream over EventSource

The SSE stream is consumed using `fetch` with `ReadableStream` rather than the browser's native `EventSource` API, because `EventSource` cannot send a custom `Authorization` header, which this backend requires for authenticated access to the stream endpoint.

---

## 26. Settings and User Account Architecture

The settings domain handles authenticated user profile and account lifecycle operations.

### Supported Settings Operations

- update profile
- create avatar upload URL
- confirm avatar upload
- change password
- request account deletion
- confirm account deletion
- get/update user preferences

### Security Characteristics

Sensitive actions are protected with extra safeguards:
- password change updates the token revocation reference
- account deletion requires current-password confirmation
- account deletion also uses OTP-based email confirmation before final removal

This reflects a conservative design for destructive account operations.

---

## 27. Organization Architecture

The organization feature exists as an early or demo-oriented domain and is not yet the central product focus.

### Current Capabilities

- create organization
- list join requests
- update member status

### Architectural Role

This feature establishes the groundwork for future organization-based workflows without yet driving the main product architecture.

It is best understood as a direction-setting domain rather than the operational center of the current platform.

---

## 28. Storage and File Security Model

The backend follows a strict storage-security principle:

- files are not treated as public application data by default
- uploads use signed upload URLs
- downloads use signed access URLs where appropriate
- file names are sanitized before storage
- storage object deletion is handled through backend logic

This prevents the frontend from becoming the authority over object storage and allows the backend to keep file access aligned with ownership and enrollment rules.

### Public vs Private Buckets

The architecture distinguishes between:
- **public-style assets** such as avatars
- **private educational content** such as course materials

This separation reflects different security expectations for different file categories.

---

## 29. Data Access Strategy

The visible implementation uses explicit SQL queries in feature services rather than deeply embedding ORM models into every workflow.

### Advantages

- clear query intent
- exact join control
- fine-grained response shaping
- easy feature-specific optimizations
- straightforward hierarchy validation

### Trade-Offs

- more manual SQL writing
- more explicit mapping logic
- stronger need for disciplined service design

Within this backend, the service-oriented architecture already provides the right place for that responsibility.

---

## 30. Transaction and State Handling

Many feature workflows involve multi-step state changes rather than single inserts or updates.

Examples include:
- registration followed by verification flow
- invitation upload followed by invitation sending
- upload initialization followed by confirmation
- account deletion request followed by OTP confirmation

This means the backend is designed around stateful workflows, not just CRUD endpoints.

The service layer is therefore responsible not only for validation and database writes, but also for orchestrating transitions between meaningful business states.

---

## 31. Error Handling Philosophy

The backend uses explicit HTTP exceptions to represent failures clearly and intentionally.

Typical failure categories include:

- `401 Unauthorized` for invalid or missing identity
- `403 Forbidden` for valid identity with insufficient permission or invalid access context
- `404 Not Found` for missing entities within the expected hierarchy
- `409 Conflict` for conflicting state such as duplicate registration
- `422 Unprocessable Entity` for invalid identifiers, invalid file input, or malformed business payloads
- `500+` class errors for internal processing or infrastructure failures

This helps feature behavior remain predictable and easier to debug.

---

## 32. AI Integration Boundary

The backend is designed to integrate with AI workflows without giving the AI layer direct authority over application state.

### Intended AI Responsibilities

- extract topics and subtopics from materials
- extract learning outcomes from materials
- generate questions based on selected content scope
- support learner guidance and performance analysis

### Backend Responsibilities Around AI

- validate and persist AI-generated structures
- enforce hierarchy correctness
- control who can create, update, or delete AI-assisted content
- keep AI output as suggested content until it becomes accepted application state

This separation is important because AI output should enhance backend workflows, not bypass backend rules.

### Implemented Integration Boundary

This separation is now reinforced by a reusable AI service integration layer in `core` together with a dedicated AI callback feature for inbound orchestration.

Feature services are not expected to manage transport, signing, callback verification, or request tracking as part of their local business logic.  
Instead, they prepare the feature-specific request body and identify the target AI operation, while shared infrastructure handles:

- request envelope construction
- transport dispatch
- request signing
- callback verification
- request lifecycle tracking

On the inbound side, the backend now exposes a generic callback endpoint that dispatches by `operation_type` after request-boundary verification succeeds.  
This keeps callback transport/authenticity handling separate from operation-specific persistence logic.

This keeps feature services focused on domain rules while ensuring AI communication behavior remains consistent across the backend.

### Boundary Between Shared Integration Logic and Backend-Specific State

The AI integration design also preserves a clear boundary between:

- integration rules that can be shared with the AI service team
- backend-only concerns tied to Learnova's persistence and operational model

For example:
- request protocol structure and signature rules belong to the shared integration contract
- request-log persistence, entity correlation, and operational status tracking remain backend-specific responsibilities

This boundary is important because the AI service should be able to participate in a stable communication contract without gaining ownership of backend state management.

At the current stage, the backend implements four callback-driven AI operations: `content_structure_generation`, `question_generation`, `exam_grading`, and `rag_chat`. Each is handled by its own operation-specific handler behind the same registry-based dispatch described in Section 30.6. The earlier temporary name `material_extraction` should be treated as deprecated.
The earlier temporary name `material_extraction` should be treated as deprecated.

---

## 33. AI Communication Security

The backend secures communication with AI services using an HMAC-based request authentication model backed by a shared secret.

This mechanism is not limited to a generic "sign requests" rule.  
It is part of a structured communication model that protects both outbound backend requests and inbound AI callbacks.

### Outbound Request Security

Before sending a request to the AI service, the backend prepares canonical signing inputs derived from:

- HTTP method
- target path
- request ID
- timestamp
- body hash

This keeps signature generation deterministic and ensures that the signature is tied to the actual request identity and payload rather than to loosely formatted raw JSON.

### Deterministic Body Hashing

To support stable signing behavior, the backend uses deterministic JSON serialization for the request body before hashing.

This is important because equivalent payloads must produce the same body hash even when serialization details could otherwise vary.  
Without canonical serialization behavior, signatures could become unreliable across services.

### Standard Integration Headers

The protocol uses a standard header set for service-to-service communication:

- `Learnova-Request-Id`
- `Learnova-Timestamp`
- `Learnova-Signature`

These headers are part of the callback verification and signing model rather than optional transport metadata.

### Callback Verification at the Request Boundary

AI callbacks or asynchronous responses are verified before they are allowed to enter service-level business logic.

This is a critical architectural rule because external payloads must not reach domain workflows until request authenticity has been validated.  
As a result, callback verification is treated as a request-boundary concern rather than as feature-specific service logic.

The verifier returns a normalized `VerifiedAICallbackRequest` object containing:

- `request_id`
- `timestamp`
- `signature`
- `payload`
- `raw_body`

That normalized object is what gets passed downstream into callback-handling service logic after authenticity checks succeed.

### Time-Based Validation Controls

The communication layer also supports environment/config-driven controls such as:

- AI service base URL
- shared secret
- outbound timeout
- allowed timestamp drift

These settings allow the backend to enforce consistent integration security behavior across environments while keeping deployment-specific values out of feature code.

### Security Purpose

This model helps ensure:

- request integrity
- callback authenticity
- resistance to tampering
- reduced risk of replay-style misuse within the allowed drift model
- consistent enforcement of service-to-service trust boundaries

The result is an AI communication model that is explicit, reusable, and aligned with the backend principle that external systems must be verified before they influence application behavior.


## 34. AI Request Tracking and Lifecycle Logging

The backend includes a dedicated request-tracking layer for AI communication so that outbound operations can be monitored across their full lifecycle.

This tracking is implemented as a backend-specific operational concern rather than as part of the shareable protocol itself.

### Purpose of Request Tracking

AI workflows are often asynchronous and multi-step.  
For that reason, the backend needs more than simple transport success/failure awareness.

Request tracking supports:

- correlating outbound requests with later callbacks or responses
- monitoring status transitions over time
- debugging failed or delayed AI operations
- auditing what payload was sent and what payload was returned
- linking AI operations back to relevant backend context such as course or entity scope

### Tracked Request Data

The request log model is designed to capture both communication metadata and operational state, including:

- `request_id`
- `course_id`
- `operation_type`
- `http_method`
- `target_endpoint`
- `request_payload`
- `response_payload`
- `status`
- `error_message`
- `primary_entity_type`
- `primary_entity_id`
- lifecycle timestamps such as creation, send, callback receipt, completion, update, and last error timing

This gives the backend a durable record of AI communication activity instead of relying on temporary in-memory or console-only logging.

### Lifecycle-Oriented Observability

The request log is intentionally lifecycle-oriented rather than insert-only.

This allows the backend to observe important milestones such as:

- request created
- request sent
- callback received
- request completed
- request failed or last encountered an error

That lifecycle visibility is especially valuable for future AI-assisted workflows that may involve delayed processing, retries, moderation steps, or post-processing decisions.

### Separation from Shared Integration Rules

Although request tracking is closely related to AI communication, it is not part of the shareable backend-to-AI contract itself.

The AI service needs to follow the protocol and signature model, but it does not need to know how Learnova stores request logs, associates them with internal entities, or manages operational observability in the database.

This distinction keeps the protocol portable while preserving backend ownership of its own monitoring and persistence behavior.

---


## 35. AI Callback Handling Architecture

The backend now includes implemented callback support for asynchronous AI workflows.

This is not just a protocol capability in `core`.  
It is a full feature-level architecture that receives verified AI callbacks, correlates them with tracked requests, dispatches them by operation type, and persists accepted results through backend-controlled business logic.

### 35.1 Callback Entry Point

The implemented callback endpoint is:

- `POST /ai/callback`

This endpoint is exposed through a dedicated AI router under `app/domains/ai/` and is registered in `main.py` as part of the application router composition.

### 35.2 Thin Router Design

The AI callback router remains intentionally thin.

Its responsibility is limited to:

- receiving the raw `Request`
- accessing the database session
- calling `verify_ai_callback_request(...)`
- passing the verified result into `service.handle_ai_callback(...)`

It does not contain operation-specific business logic, persistence rules, or transaction orchestration.

### 35.3 Request-Boundary Verification

Callback authenticity is verified before the request enters business logic.

That verification includes:

- required header presence
- timestamp validation
- signature validation
- JSON body parsing

Only after this succeeds does the backend pass a `VerifiedAICallbackRequest` object into the feature service.  
This preserves the architectural rule that external payloads must be authenticated before they influence application behavior.

### 35.4 AI Feature Package Structure

The callback feature is implemented under:

- `app/domains/ai/`

Its internal structure follows the same architectural discipline as the rest of the backend while allowing a justified handler-driven extension:

- `router.py`
- `service.py`
- `handlers.py`
- `helpers.py` when needed

This is an intentional design choice rather than an accidental deviation from the standard feature pattern.  
The callback feature is handler-driven by nature because one verified entrypoint may dispatch to multiple AI operation handlers over time.

### 35.5 Generic Service Responsibilities

The AI feature service is designed to stay as generic as possible.

Its responsibilities include:

- accepting `VerifiedAICallbackRequest`
- extracting `operation_type`
- looking up the tracked AI request by `request_id`
- validating that the request exists
- validating that the operation type matches
- rejecting expired requests
- rejecting already-processed callbacks
- marking callback receipt in the request lifecycle
- dispatching to the correct operation handler
- marking the AI request as completed after success
- marking the AI request as failed after unexpected failure
- owning the transaction boundary

This service deliberately does not contain operation-specific content insertion logic.

### 35.6 Registry-Based Operation Dispatch

Callback dispatch is registry-based rather than hardcoded as one growing conditional flow.

This allows the backend to support additional AI operations later by:

- adding a new handler
- registering it in the dispatch registry

without redesigning the generic callback service.

This design is no longer purely forward-looking — the registry now dispatches across four distinct operations (`content_structure_generation`, `question_generation`, `exam_grading`, `rag_chat`), each added without modifying the generic callback service itself, confirming the original extensibility goal in practice rather than just in intent.


### 35.7 Current Implemented Operation

The backend currently implements four callback-handled operations:

- **`content_structure_generation`** — extracts topics, subtopics, and learning outcomes from an uploaded material
- **`question_generation`** — inserts AI-generated questions into the course question bank for selected topics
- **`exam_grading`** — delivers AI-assessed grading results for essay and short-answer questions on a submitted exam attempt
- **`rag_chat`** — delivers the AI study companion's reply to a student message in the AI chat domain

These are the finalized operation names used across request dispatch, callback payloads, operation-type definitions, and backend documentation. The earlier temporary name `material_extraction` should be treated as deprecated.

Each operation has its own dedicated handler under the registry-based dispatch model (Section 30.6), but all four share the same generic service responsibilities (Section 30.5), request-boundary verification (Section 30.3), and transaction strategy (Section 30.13).

### 35.8 Operation-Specific Handler Responsibilities

The current handler is responsible only for `content_structure_generation` business logic.

Its responsibilities include:

- reading `payload["body"]`
- extracting `course_id`, `module_id`, `material_id`, `topics`, `learning_outcomes`, and `topic_learning_outcome_relations`
- performing basic callback structure validation
- validating important identity fields such as `course_id` and `material_id` against the tracked AI request
- invoking the relevant persistence helpers
- updating material AI-processing state after successful persistence
- returning a small summary result

The handler does not perform callback verification, request-log lookup, lifecycle orchestration, or transaction commits/rollbacks.

### 35.9 Persistence Helpers and Responsibility Split

Persistence is intentionally divided across feature-scoped helpers.

#### Topics Helper

The topics feature provides:

- `bulk_insert_ai_topics(...)`

This helper inserts AI-generated topics using a two-pass strategy:

- pass 1 inserts topic rows without `parent_topic_id`
- pass 2 resolves `parent_temp_id` and updates `parent_topic_id`

It returns an in-memory mapping from:

- `topic_temp_id -> topic_db_id`

#### Learning Outcomes Helper

The learning outcomes feature provides:

- `bulk_insert_ai_learning_outcomes(...)`

This helper inserts AI-generated learning outcomes and returns an in-memory mapping from:

- `learning_outcome_temp_id -> learning_outcome_db_id`

#### AI Feature Helpers

The AI feature helpers provide operations such as:

- `insert_topic_learning_outcome_relations(...)`
- `mark_material_ai_processing_completed(...)`

The relation helper uses the in-memory mappings produced by topic and learning-outcome insertion helpers to populate the relation table.  
The material helper updates:

- `is_ai_processed = TRUE`
- `ai_processed_at = NOW()`
- `updated_at = NOW()`

### 35.10 Temporary ID Mapping Strategy

The backend does not persist AI temporary identifiers as long-term database reference keys.

Instead, temp IDs exist only during the processing of the current callback, where they are used to build in-memory mappings such as:

- `topic_temp_id -> topic_id`
- `learning_outcome_temp_id -> learning_outcome_id`

After persistence completes, these temp IDs are not retained as durable application identifiers.  
Accordingly, `ai_ref_key` is not part of the intended long-term linkage strategy for this flow.

### 35.11 Idempotent Relation Insertion

Topic-to-learning-outcome relation insertion is intentionally idempotent.

To tolerate duplicate callbacks, retries, or repeated network delivery, relation insertion uses conflict-safe behavior equivalent to:

- `ON CONFLICT (topic_id, learning_outcome_id) DO NOTHING`

This prevents avoidable crashes and unnecessary rollbacks when a duplicate relation arrives during callback replay scenarios.

### 35.12 Material AI Processing State

Successful callback processing does not repurpose the material's general status field as AI completion state.

Instead, AI completion is tracked separately through dedicated material fields such as:

- `is_ai_processed`
- `ai_processed_at`
- `updated_at`

This preserves a clean separation between the material's upload/status lifecycle and its AI-processing lifecycle.

### 35.13 Transaction Strategy

Transaction ownership remains centralized in the generic AI callback service.

The adopted strategy is:

- helpers do not commit
- helpers do not rollback
- handlers do not commit
- handlers do not rollback
- the generic service performs one commit after the full operation succeeds
- the generic service performs rollback on failure

This keeps the callback flow atomic and avoids fragmented transaction control across layers.

### 35.14 Flush Usage Within the Callback Flow

The service performs `db.flush()` after marking callback receipt.

This keeps the callback-received update inside the same transaction without introducing a partial commit.  
If a later handler step fails, the entire operation can still be rolled back atomically.

### 35.15 AI-Generated Content State

Rows created from AI callback output are inserted as AI-generated but not yet reviewed.

For the current content-structure flow, this means:

- topics are stored with `is_ai_generated = TRUE` and `is_reviewed = FALSE`
- learning outcomes are stored with `is_ai_generated = TRUE` and `is_reviewed = FALSE`

This keeps AI-produced instructional content distinguishable from manually authored or explicitly reviewed content.

---

## 36. Security Model Summary

The backend security model combines multiple layers:

- JWT access-token authentication
- refresh-token cookie flow
- current-user dependency validation
- email verification enforcement
- role-based access control
- ownership-based write protection
- enrollment-based read access
- token-backed sensitive workflows
- storage access through signed URLs
- password hashing and token revocation logic

This layered approach is especially important in an educational system where learning materials, account identity, assessment content, and learner-related data all need controlled access.

---

## 37. Current Architectural Focus

The backend's architectural focus has expanded from a purely instructor-driven foundation into a system that also supports core learner-facing workflows, while the instructor-authored content layer underneath remains foundational.

Its primary focus areas now include:

- authenticated account lifecycle
- course ownership, visibility, and access control
- structured instructional hierarchy
- file-backed material workflows
- learning outcomes and topic mapping
- a question bank with both manual and AI-assisted authoring
- a full exam authoring, publishing, and grading workflow
- student-facing exam attempts with mixed automatic and AI-assisted grading
- a real-time, RAG-based AI study companion
- secure, explicit backend validation across both instructor and student-facing flows

This sequencing makes sense because the learner experience depends on a strong instructor-authored content structure beneath it.

---

## 38. Future Architectural Direction

The current architecture is already positioned to support the next major phases of the platform, including:

- per-topic student performance analytics and weak-point tracking, built on top of submitted exam attempt data (designed, not yet implemented)
- deeper AI extraction integration improvements
- broader organization-based environments
- expanded learner-side study flows beyond the current AI chat companion

Because the backend is modular, feature-oriented, and service-driven, these future additions can be integrated incrementally without requiring a full architectural rewrite.

---

## 39. Summary

The Learnova backend follows a feature-oriented, service-driven architecture where the backend acts as the central authority for data integrity, authorization, storage access, and workflow orchestration.

Its design is defined by:

- modular feature boundaries
- thin routers and service-centered logic
- explicit validation and authorization rules
- secure token and storage workflows
- structured educational hierarchy modeling
- extensible question-bank architecture
- clear preparation for AI-assisted product growth

This architecture provides a strong and realistic foundation for turning Learnova from a graduation project into a production-capable educational platform.

---

## 40. Anti-Patterns to Avoid

- Do not trust frontend-provided IDs without hierarchy validation
- Do not expose storage keys directly
- Do not allow AI to write directly to database
- Do not bypass service layer

---

## 41. Development Rules (Non-Negotiable)

- All database access MUST use sqlalchemy.text(...)
- No ORM relationships inside services
- All authorization MUST be validated in service layer
- No business logic in routers
- All endpoints MUST validate hierarchy (course → module → material → topic)
- AI output MUST NEVER be trusted directly