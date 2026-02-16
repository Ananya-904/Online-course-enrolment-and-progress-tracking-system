-- =============================================================================
-- Online Course Enrolment and Progress Tracking System
-- Schema Definition
-- MySQL-compatible SQL
-- =============================================================================

-- Drop existing objects if re-running (development only)
-- Uncomment below for clean reinstall:
-- SET FOREIGN_KEY_CHECKS = 0;
-- DROP TABLE IF EXISTS Scores, Quizzes, Progress, Enrollments, Modules, Courses, Users;
-- SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- USERS
-- Stores all system users: Students, Instructors, and Admins.
-- -----------------------------------------------------------------------------

create database online_course;
use online_course;

CREATE TABLE Users (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    name            VARCHAR(100)    NOT NULL,
    email           VARCHAR(255)    NOT NULL UNIQUE,
    role            ENUM('Student', 'Instructor', 'Admin') NOT NULL DEFAULT 'Student',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_users_role (role),
    INDEX idx_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'System users: Students, Instructors, Admins';

-- -----------------------------------------------------------------------------
-- COURSES
-- Course catalog; each course belongs to one instructor.
-- -----------------------------------------------------------------------------
CREATE TABLE Courses (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    title           VARCHAR(200)    NOT NULL,
    description     TEXT,
    instructor_id   INT             NOT NULL,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (instructor_id) REFERENCES Users(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_courses_instructor (instructor_id),
    INDEX idx_courses_title (title(50))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'Course catalog; instructor_id references Users';

-- -----------------------------------------------------------------------------
-- MODULES
-- Learning units within a course; ordered by module_order.
-- -----------------------------------------------------------------------------
CREATE TABLE Modules (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    course_id       INT             NOT NULL,
    module_name     VARCHAR(200)    NOT NULL,
    module_order    INT             NOT NULL DEFAULT 1,
    FOREIGN KEY (course_id) REFERENCES Courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_modules_course (course_id),
    INDEX idx_modules_order (course_id, module_order),
    UNIQUE KEY uk_module_order_per_course (course_id, module_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'Course modules; ordered within each course';

-- -----------------------------------------------------------------------------
-- ENROLLMENTS
-- Student enrollments in courses; one row per user-course pair.
-- -----------------------------------------------------------------------------
CREATE TABLE Enrollments (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    user_id         INT             NOT NULL,
    course_id       INT             NOT NULL,
    date_enrolled   DATE            NOT NULL,
    FOREIGN KEY (user_id) REFERENCES Users(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (course_id) REFERENCES Courses(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uk_user_course (user_id, course_id),
    INDEX idx_enrollments_user (user_id),
    INDEX idx_enrollments_course (course_id),
    INDEX idx_enrollments_date (date_enrolled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'Student enrollments; one record per user per course';

-- -----------------------------------------------------------------------------
-- PROGRESS
-- Per-enrollment, per-module completion; links to quiz scores.
-- -----------------------------------------------------------------------------
CREATE TABLE Progress (
    id                  INT             PRIMARY KEY AUTO_INCREMENT,
    enrollment_id       INT             NOT NULL,
    module_id          INT             NOT NULL,
    completion_status   BOOLEAN         NOT NULL DEFAULT FALSE,
    completion_date     DATETIME        NULL,
    FOREIGN KEY (enrollment_id) REFERENCES Enrollments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (module_id) REFERENCES Modules(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uk_enrollment_module (enrollment_id, module_id),
    INDEX idx_progress_enrollment (enrollment_id),
    INDEX idx_progress_module (module_id),
    INDEX idx_progress_status (completion_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'Module completion per enrollment; one row per enrollment-module';

-- -----------------------------------------------------------------------------
-- QUIZZES
-- Quiz metadata per module; max_score defines scale.
-- -----------------------------------------------------------------------------
CREATE TABLE Quizzes (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    module_id       INT             NOT NULL,
    max_score       INT             NOT NULL DEFAULT 100,
    FOREIGN KEY (module_id) REFERENCES Modules(id) ON DELETE CASCADE ON UPDATE CASCADE,
    UNIQUE KEY uk_quiz_per_module (module_id),
    INDEX idx_quizzes_module (module_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'One quiz per module; max_score for normalization';

-- -----------------------------------------------------------------------------
-- SCORES
-- Quiz attempt scores; linked to Progress (enrollment + module).
-- -----------------------------------------------------------------------------
CREATE TABLE Scores (
    id              INT             PRIMARY KEY AUTO_INCREMENT,
    progress_id     INT             NOT NULL,
    score           DECIMAL(5,2)    NOT NULL,
    attempt_date    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (progress_id) REFERENCES Progress(id) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_scores_progress (progress_id),
    INDEX idx_scores_date (attempt_date),
    CONSTRAINT chk_score_non_negative CHECK (score >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
COMMENT 'Quiz scores per progress record; supports multiple attempts';

-- -----------------------------------------------------------------------------
-- End of schema
-- -----------------------------------------------------------------------------
