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
- organizations
- settings

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
│  ├── features/
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

#### `app/features/`
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

Some features also include helper modules where needed.

### Feature Packages

```text
features/
├── auth/
├── courses/
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
- invitation upload via Excel
- invitation sending
- invitation acceptance
- listing current user’s accessible courses
- listing course invitations

### Architectural Importance

Courses establish:
- the main instructor ownership boundary
- the enrollment access model
- the root container for modules, materials, learning outcomes, topics, and questions

---

## 15. Invitation and Access Model

A key design choice in Learnova is support for both open and controlled course access.

### 15.1 Supported Access Patterns

- **Open enrollment**
- **Invitation-based controlled enrollment**

### 15.2 Invitation Flow

For controlled access, instructors can:

- upload an Excel sheet containing student emails
- extract and validate email addresses
- store invitation records
- send invitation emails
- allow invited students to accept invitations through a token-backed endpoint

This is particularly important for real teaching scenarios where instructors want to restrict access to a known section or cohort.

---

## 16. Module Architecture

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

## 17. Material Architecture

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

---

## 18. Topic Architecture

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

## 19. Learning Outcome Architecture

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

## 20. Question Architecture

The question domain is one of the most important backend areas because it directly supports the product’s question-bank identity.

### 20.1 Topic-Scoped Question Ownership

All questions are linked directly to a `topic_id`.

This is a deliberate architectural choice because:
- topics represent the most precise instructional content scope
- learning outcomes can still be inferred through topic relationships
- questions remain grounded in course content rather than floating independently

---

### 20.2 Unified Question Table Strategy

The backend uses a unified question model instead of separate tables for each question type.

This supports:
- centralized question management
- consistent retrieval
- simpler question-bank aggregation
- easier future assessment composition

---

### 20.3 Type-Aware Validation

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

### 20.4 Multi-Scope Question Retrieval

The backend supports question retrieval across multiple scopes:

- by topic
- by material
- by module
- by course
- by question ID

Even though questions are directly topic-scoped, broader listing endpoints derive results through the hierarchy instead of duplicating ownership across entities.

---

### 20.5 Question Bank Foundation

At the product level, the implemented question domain forms the foundation of the **course question bank**.

This is strategically important because the next major workflow is assessment construction from approved questions, rather than building a disconnected exam system from scratch.

---

## 21. Settings and User Account Architecture

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

## 22. Organization Architecture

The organization feature exists as an early or demo-oriented domain and is not yet the central product focus.

### Current Capabilities

- create organization
- list join requests
- update member status

### Architectural Role

This feature establishes the groundwork for future organization-based workflows without yet driving the main product architecture.

It is best understood as a direction-setting domain rather than the operational center of the current platform.

---

## 23. Storage and File Security Model

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

## 24. Data Access Strategy

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

## 25. Transaction and State Handling

Many feature workflows involve multi-step state changes rather than single inserts or updates.

Examples include:
- registration followed by verification flow
- invitation upload followed by invitation sending
- upload initialization followed by confirmation
- account deletion request followed by OTP confirmation

This means the backend is designed around stateful workflows, not just CRUD endpoints.

The service layer is therefore responsible not only for validation and database writes, but also for orchestrating transitions between meaningful business states.

---

## 26. Error Handling Philosophy

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

## 27. AI Integration Boundary

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

---

## 28. AI Communication Security

The backend is designed to secure communication with AI services using HMAC-signed requests. This mechanism is part of the agreed architecture and is intended to be enforced as AI integrations are finalized.

- The backend signs outgoing requests before sending them to AI services.
- AI services verify the signature before processing the request.
- AI services sign callbacks or asynchronous responses before sending them back.
- The backend verifies the callback signature before accepting or processing any returned payload.

This model helps ensure request integrity, prevents unauthorized service-to-service calls, and protects the AI integration boundary from tampering..

---

## 29. Security Model Summary

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

## 30. Current Architectural Focus

The current backend is intentionally centered on the instructor-side foundation of the platform.

Its primary focus areas are:

- authenticated account lifecycle
- course ownership and access control
- structured instructional hierarchy
- file-backed material workflows
- learning outcomes and topic mapping
- course question bank foundation
- secure, explicit backend validation

This sequencing makes sense because the learner experience depends on a strong instructor-authored content structure beneath it.

---

## 31. Future Architectural Direction

The current architecture is already positioned to support the next major phases of the platform, including:

- deeper AI extraction integration
- AI-assisted learner support
- richer student performance analytics
- full assessment and exam workflows
- broader organization-based environments
- expanded learner-side study flows

Because the backend is modular, feature-oriented, and service-driven, these future additions can be integrated incrementally without requiring a full architectural rewrite.

---

## 32. Summary

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

## 33. Anti-Patterns to Avoid

- Do not trust frontend-provided IDs without hierarchy validation
- Do not expose storage keys directly
- Do not allow AI to write directly to database
- Do not bypass service layer

---

## 34. Development Rules (Non-Negotiable)

- All database access MUST use sqlalchemy.text(...)
- No ORM relationships inside services
- All authorization MUST be validated in service layer
- No business logic in routers
- All endpoints MUST validate hierarchy (course → module → material → topic)
- AI output MUST NEVER be trusted directly