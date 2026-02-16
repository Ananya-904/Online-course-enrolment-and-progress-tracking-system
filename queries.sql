-- =============================================================================
-- Online Course Enrolment and Progress Tracking System
-- Performance Reports and Core Queries
-- MySQL-compatible SQL
-- =============================================================================
-- Run schema.sql, sample_data.sql, views.sql, and procedures.sql first.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- CORE QUERIES (from requirements)
-- -----------------------------------------------------------------------------

-- Enroll a student (example)
-- INSERT INTO Enrollments (user_id, course_id, date_enrolled)
-- VALUES (3, 5, CURDATE());
-- Or use stored procedure: CALL EnrollStudent(3, 5);

-- Update progress: mark module as completed
-- CALL UpdateModuleProgress(1, 1, TRUE);

-- Update progress: record quiz score
-- CALL RecordQuizScore(1, 85.50);

-- Fetch student performance: course completion %, avg quiz score, ranking
-- CALL GenerateStudentReport();


-- =============================================================================
-- PERFORMANCE REPORTS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Top 5 students by (average) score
-- Uses: AVG, ORDER BY, LIMIT
-- -----------------------------------------------------------------------------
SELECT
    user_id,
    student_name,
    student_email,
    total_quiz_attempts,
    avg_score AS average_score
FROM v_average_score_per_student
ORDER BY avg_score DESC, user_id
LIMIT 5;


-- -----------------------------------------------------------------------------
-- 2. Most popular courses (by enrollment count)
-- Uses: COUNT, GROUP BY, ORDER BY
-- -----------------------------------------------------------------------------
SELECT
    c.id    AS course_id,
    c.title AS course_title,
    COUNT(e.id) AS enrollment_count
FROM Courses c
LEFT JOIN Enrollments e ON e.course_id = c.id
GROUP BY c.id, c.title
ORDER BY enrollment_count DESC, c.id;


-- -----------------------------------------------------------------------------
-- 3. Completion percentage per course
-- Uses: COUNT, SUM, AVG (completion rate)
-- -----------------------------------------------------------------------------
SELECT
    course_id,
    course_title,
    total_enrollments,
    completed_count,
    completion_rate_pct AS completion_percentage
FROM v_course_completion_rate
ORDER BY completion_rate_pct DESC, course_id;


-- -----------------------------------------------------------------------------
-- 4. Average score per module
-- Uses: AVG, COUNT, GROUP BY
-- -----------------------------------------------------------------------------
SELECT
    m.id         AS module_id,
    m.module_name,
    m.course_id,
    c.title      AS course_title,
    COUNT(s.id)  AS attempt_count,
    ROUND(AVG(s.score), 2) AS avg_score,
    MAX(s.score) AS max_score,
    MIN(s.score) AS min_score
FROM Modules m
INNER JOIN Courses c ON c.id = m.course_id
LEFT JOIN Progress pr ON pr.module_id = m.id
LEFT JOIN Scores s ON s.progress_id = pr.id
GROUP BY m.id, m.module_name, m.course_id, c.title
ORDER BY m.course_id, m.module_order, m.id;


-- -----------------------------------------------------------------------------
-- 5. Student ranking leaderboard (all students with scores, ranked by avg score)
-- Uses: AVG, ORDER BY; rank computed in outer query for compatibility
-- -----------------------------------------------------------------------------
SELECT
    user_id,
    student_name,
    student_email,
    total_quiz_attempts,
    avg_score,
    max_score,
    min_score,
    @rank := @rank + 1 AS rank_position
FROM v_average_score_per_student
CROSS JOIN (SELECT @rank := 0) AS r
ORDER BY avg_score DESC, user_id;


-- -----------------------------------------------------------------------------
-- Additional report: Top performers per course (with rank)
-- Uses view v_top_performers_per_course; rank via session variable
-- -----------------------------------------------------------------------------
SELECT
    course_id,
    course_title,
    user_id,
    student_name,
    avg_score,
    completed_modules,
    total_modules,
    completion_pct,
    @cur := IF(@course = course_id, @cur + 1, 1) AS rank_in_course,
    @course := course_id AS _course
FROM v_top_performers_per_course
CROSS JOIN (SELECT @cur := 0, @course := NULL) AS v
ORDER BY course_id, avg_score DESC, user_id;


-- -----------------------------------------------------------------------------
-- End of queries
-- -----------------------------------------------------------------------------
