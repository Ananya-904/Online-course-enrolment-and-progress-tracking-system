-- =============================================================================
-- Online Course Enrolment and Progress Tracking System
-- Stored Procedures
-- MySQL-compatible SQL
-- =============================================================================
-- Run schema.sql before this file.
-- =============================================================================

DELIMITER //

-- -----------------------------------------------------------------------------
-- EnrollStudent
-- Enrolls a user (student) in a course. Inserts one row into Enrollments.
-- Inputs: p_user_id INT, p_course_id INT
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS EnrollStudent//
CREATE PROCEDURE EnrollStudent(
    IN p_user_id   INT,
    IN p_course_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    -- Validate: user and course must exist
    IF p_user_id IS NULL OR p_course_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'EnrollStudent: user_id and course_id are required.';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM Users
    WHERE id = p_user_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'EnrollStudent: User not found.';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM Courses
    WHERE id = p_course_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'EnrollStudent: Course not found.';
    END IF;

    -- Prevent duplicate enrollment
    SELECT COUNT(*) INTO v_exists
    FROM Enrollments
    WHERE user_id = p_user_id AND course_id = p_course_id;

    IF v_exists > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'EnrollStudent: User is already enrolled in this course.';
    END IF;

    INSERT INTO Enrollments (user_id, course_id, date_enrolled)
    VALUES (p_user_id, p_course_id, CURDATE());
END//

-- -----------------------------------------------------------------------------
-- UpdateModuleProgress
-- Updates completion status for an enrollment-module pair.
-- Creates or updates Progress row; sets completion_date when status = TRUE.
-- Inputs: p_enrollment_id INT, p_module_id INT, p_status BOOLEAN
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS UpdateModuleProgress//
CREATE PROCEDURE UpdateModuleProgress(
    IN p_enrollment_id INT,
    IN p_module_id     INT,
    IN p_status        BOOLEAN
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    IF p_enrollment_id IS NULL OR p_module_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'UpdateModuleProgress: enrollment_id and module_id are required.';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM Progress
    WHERE enrollment_id = p_enrollment_id AND module_id = p_module_id;

    IF v_exists > 0 THEN
        UPDATE Progress
        SET completion_status = p_status,
            completion_date   = IF(p_status = TRUE, COALESCE(completion_date, NOW()), NULL)
        WHERE enrollment_id = p_enrollment_id AND module_id = p_module_id;
    ELSE
        INSERT INTO Progress (enrollment_id, module_id, completion_status, completion_date)
        VALUES (
            p_enrollment_id,
            p_module_id,
            p_status,
            IF(p_status = TRUE, NOW(), NULL)
        );
    END IF;
END//

-- -----------------------------------------------------------------------------
-- RecordQuizScore
-- Inserts a quiz score for a given progress record (enrollment + module).
-- Inputs: p_progress_id INT, p_score DECIMAL(5,2)
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS RecordQuizScore//
CREATE PROCEDURE RecordQuizScore(
    IN p_progress_id INT,
    IN p_score       DECIMAL(5,2)
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    IF p_progress_id IS NULL OR p_score IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RecordQuizScore: progress_id and score are required.';
    END IF;

    IF p_score < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RecordQuizScore: score must be non-negative.';
    END IF;

    SELECT COUNT(*) INTO v_exists
    FROM Progress
    WHERE id = p_progress_id;

    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RecordQuizScore: Progress record not found.';
    END IF;

    INSERT INTO Scores (progress_id, score, attempt_date)
    VALUES (p_progress_id, p_score, NOW());
END//

-- -----------------------------------------------------------------------------
-- GenerateStudentReport
-- Returns a performance summary: course completion %, average quiz score.
-- Ranking within course is available via view v_student_leaderboard.
-- No input parameters; returns result set.
-- -----------------------------------------------------------------------------
DROP PROCEDURE IF EXISTS GenerateStudentReport//
CREATE PROCEDURE GenerateStudentReport()
BEGIN
    SELECT
        u.id           AS user_id,
        u.name         AS student_name,
        u.email        AS student_email,
        c.id           AS course_id,
        c.title        AS course_title,
        COUNT(DISTINCT m.id) AS total_modules,
        COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END) AS completed_modules,
        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END)
                / NULLIF(COUNT(DISTINCT m.id), 0),
            2
        ) AS completion_pct,
        COALESCE(ROUND(AVG(s.score), 2), 0)     AS avg_quiz_score,
        COUNT(s.id)                             AS quiz_attempts
    FROM Users u
    INNER JOIN Enrollments e ON e.user_id = u.id
    INNER JOIN Courses c ON c.id = e.course_id
    INNER JOIN Modules m ON m.course_id = c.id
    LEFT JOIN Progress pr ON pr.enrollment_id = e.id AND pr.module_id = m.id
    LEFT JOIN Scores s ON s.progress_id = pr.id
    WHERE u.role = 'Student'
    GROUP BY u.id, u.name, u.email, c.id, c.title, e.id;
END//

DELIMITER ;

-- -----------------------------------------------------------------------------
-- End of procedures
-- -----------------------------------------------------------------------------
