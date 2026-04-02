# Learnova - Project Overview

## 1. Project Overview

Learnova is an AI-enhanced learning platform designed to support both instructors and learners through intelligent content structuring, question generation, and guided learning experiences.

The platform combines course creation workflows with AI-powered assistance to transform raw learning materials into structured, interactive, and assessment-ready educational content. In parallel, Learnova is built to evolve into an AI study companion that supports learners both insde the courses and outside.

---

## 2. Vision and Purpose

Learnova is built to address two core problems in modern learning environments:

1. **Instructor inefficiency**
   - Creating structured content, topics, and assessments is time-consuming and repetitive.
   - Managing question banks and analyzing student performance requires significant effort.

2. **Lack of personalized learner guidance**
   - Students often struggle to identify weak areas.
   - Learning is usually static and not adaptive to individual needs.

Learnova aims to solve this by acting as:
- A **powerful course authoring platform for instructors**
- And a **smart AI study companion for learners**

The long-term vision is to provide a system where:
- instructors can build and manage courses efficiently
- learners receive continuous, personalized, AI-guided support

---

## 3. Who Learnova Serves

### Instructor
Instructors use Learnova to:
- Create and manage courses
- Structure content into modules, materials, and topics
- Define learning outcomes
- Build and manage a course question bank
- Generate questions manually or using AI
- Control access to courses (open or invitation-based)

Instructors can use the platform independently or as part of an organization-based environment.

---

### Learner / Student

Learners use Learnova to:
- Access course content (when enrolled)
- Practice questions and assessments
- (Planned) Receive AI-driven guidance based on performance

Beyond course-based learning, Learnova is designed to act as a **direct AI study companion**, enabling learners to study their own materials and receive structured, guided support even outside formal courses.

---

### Organization (Future Direction)

Learnova is designed to support organization-based learning environments (e.g., universities, schools), where instructors and learners operate under a shared system. This capability is part of the broader product direction and will be expanded in future iterations.

---

## 4. Core Product Experience

### Instructor Workflow (Current Core Focus)

The current system is centered around the instructor experience:

- Create courses
- Organize courses into modules
- Upload materials
- Choose between:
  - AI-assisted content extraction
  - Manual structuring
- Manage:
  - topics and subtopics
  - learning outcomes
- Create and manage questions
- Build a course-level question bank

---

### Learner Experience (Evolving)

The learner experience is being built on top of the instructor workflow and includes:

- Accessing structured course content
- Practicing questions linked to specific topics
- (Upcoming) AI-assisted learning and weak-point guidance

---

## 5. Course and Content Structure

Learnova organizes educational content into a structured hierarchy:

- **Course**
  - **Learning Outcomes**
  - **Modules**
    - **Materials**
      - **Topics**
        - **Subtopics**

Key relationships:
- Questions are linked directly to **topics**
- Learning outcomes are linked to **topics** (many-to-many relationship)
- Subtopics are treated as topics with a parent relationship
- A **course question bank** is built from all questions under the course

This structure enables both:
- precise content organization
- and accurate mapping between learning objectives and assessment

---

## 6. AI-Assisted Workflows

Learnova integrates AI to automate and enhance key parts of the learning process:

### Content Structuring
From uploaded materials, the AI can extract:
- Topics
- Subtopics
- Learning outcomes

### Question Generation
The AI can generate questions:
- Based on selected topics
- With controlled types and quantities
- Aligned with the course structure

### Learning Support (Ongoing / Upcoming)
The platform is designed to support:
- learner understanding
- performance analysis
- personalized learning guidance

### AI Processing Flow (High-Level)
1. Instructor uploads material
2. Backend decides if AI processing is requested
3. Backend sends signed download URL to AI service
4. AI processes content asynchronously
5. AI sends structured JSON back to backend
6. Backend validates and persists data

---

## 7. Question Bank and Assessment Foundation

At the core of Learnova is the **course question bank system**:

- All questions are:
  - linked to topics
  - organized at the course level
- Instructors can:
  - create questions manually
  - generate questions using AI
- Questions are structured and reusable

The platform supports:
- building assessments from approved questions  
- and forming structured evaluation workflows based on the question bank

---

## 8. Access Models

Learnova supports flexible course access models:

- **Open Enrollment**  
  Any user can enroll in the course

- **Controlled Enrollment (Invitation-Based)**  
  Access is restricted to specific users via email invitations

This allows instructors to:
- run public courses
- or manage private groups (e.g., academic sections)

---

## 9. Current Scope

The current implementation focuses on building a strong instructor-driven foundation, including:

- Authentication and account management
- Instructor role workflows
- Course creation and management
- Module and material organization
- Topic and subtopic management
- Learning outcomes management
- Question creation and question bank foundation
- Invitation-based access control

---

## 10. Future Direction

Learnova is designed to expand into a more complete learning ecosystem, including:

- Organization-based learning environments
- Full learner experience and study workflows
- Advanced performance analytics and weak-point tracking
- Expanded AI study companion capabilities
- Full assessment and exam workflows built on top of the question bank

---

Learnova represents a shift from static learning systems toward an intelligent, adaptive platform where content, assessment, and guidance are all interconnected through AI.