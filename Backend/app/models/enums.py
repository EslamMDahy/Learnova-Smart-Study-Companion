from enum import Enum


class SystemRole(str, Enum):
    owner = "owner"
    admin = "admin"
    instructor = "instructor"
    assistant = "assistant"
    student = "student"

class AccountStatus(str, Enum):
    active = "active"
    suspended = "suspended"
    deleted = "deleted"
    pending_activation = "pending_activation"

# class UserTokenType(str, Enum):
#     verify_email = "verify_email"
#     reset_password = "reset_password"
#     magic_login = "magic_login"

class ThemeMode(str, Enum):
    light = "light"
    dark = "dark"
    system = "system"

class ProfileVisibility(str, Enum):
    public = "public"
    private = "private"
    connections = "connections"

class SubscriptionTier(str, Enum):
    free = "free"
    basic = "basic"
    pro = "pro"
    enterprise = "enterprise"

class SubscriptionStatus(str, Enum):
    active = "active"
    past_due = "past_due"
    canceled = "canceled"

class OrganizationMemberRole(str, Enum):
    owner = "owner"
    admin = "admin"
    instructor = "instructor"
    assistant = "assistant"
    student = "student"

class OrganizationMemberStatus(str, Enum):
    pending = "pending"
    active = "active"
    suspended = "suspended"
    inactive = "inactive"

class OrganizationInvitationRole(str, Enum):
    admin = "admin"
    instructor = "instructor"
    assistant = "assistant"
    student = "student"

class OrganizationInvitationStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    revoked = "revoked"
    expired = "expired"

class CreditWalletType(str, Enum):
    individual = "individual"
    organization = "organization"

class CreditTransactionType(str, Enum):
    earned = "earned"
    spent = "spent"
    purchased = "purchased"
    refunded = "refunded"
    bonus = "bonus"

class PaymentStatus(str, Enum):
    pending = "pending"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"


class BillingInterval(str, Enum):
    one_time = "one_time"
    monthly = "monthly"
    yearly = "yearly"

class CourseVisibilityLevel(str, Enum):
    private = "private"
    public = "public"
    unlisted = "unlisted"


class CourseType(str, Enum):
    individual = "individual"
    organization = "organization"


class CourseStatus(str, Enum):
    draft = "draft"
    published = "published"
    archived = "archived"

class CourseInstructorRole(str, Enum):
    instructor = "instructor"
    assistant = "assistant"
    co_instructor = "co-instructor"

class CourseEnrollmentStatus(str, Enum):
    pending = "pending"
    active = "active"
    suspended = "suspended"
    completed = "completed"
    dropped = "dropped"


class CourseEnrollmentType(str, Enum):
    self = "self"
    invited = "invited"
    batch = "batch"

class MaterialType(str, Enum):
    video = "video"
    pdf = "pdf"
    document = "document"
    presentation = "presentation"
    link = "link"
    quiz = "quiz"

class MaterialStatus(str, Enum):
    uploaded = "uploaded"
    processing = "processing"
    ready = "ready"
    error = "error"

class AIQuestionGenerationStatus(str, Enum):
    processing = "processing"
    completed = "completed"
    failed = "failed"

class QuestionBankPurpose(str, Enum):
    practice = "practice"
    exam = "exam"
    homework = "homework"
    quiz = "quiz"

class QuestionBankAccessLevel(str, Enum):
    public = "public"
    private = "private"
    organization = "organization"

class PracticeSessionType(str, Enum):
    practice = "practice"
    review = "review"
    test = "test"


class PracticeSessionStatus(str, Enum):
    in_progress = "in_progress"
    completed = "completed"
    abandoned = "abandoned"

class QuestionType(str, Enum):
    multiple_choice = "multiple_choice"
    true_false = "true_false"
    short_answer = "short_answer"
    essay = "essay"

class QuestionDifficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"

class QuestionSource(str, Enum):
    manual = "manual"
    ai_generated = "ai_generated"
    imported = "imported"

class QuestionApprovalStatus(str, Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"

class QuestionMasteryLevel(str, Enum):
    unattempted = "unattempted"
    beginner = "beginner"
    intermediate = "intermediate"
    advanced = "advanced"
    mastered = "mastered"

class QuickQuizDifficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"
    mixed = "mixed"


class QuickQuizStatus(str, Enum):
    generated = "generated"
    started = "started"
    completed = "completed"
    expired = "expired"


class ExamType(str, Enum):
    quiz = "quiz"
    midterm = "midterm"
    final = "final"
    practice = "practice"

class ExamSectionDifficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"
    mixed = "mixed"

class ExamAttemptStatus(str, Enum):
    in_progress = "in_progress"
    submitted = "submitted"
    graded = "graded"
    expired = "expired"

class LearningRecommendationType(str, Enum):
    material = "material"
    question = "question"
    topic_review = "topic_review"
    practice_session = "practice_session"

class AIChatContextType(str, Enum):
    general = "general"
    course = "course"
    material = "material"
    question = "question"


class AIChatMessageType(str, Enum):
    user = "user"
    assistant = "assistant"
    system = "system"

class NotificationType(str, Enum):
    system = "system"
    course = "course"
    assignment = "assignment"
    grade = "grade"
    message = "message"
    announcement = "announcement"