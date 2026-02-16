-- =============================================================================
-- Online Course Enrolment and Progress Tracking System
-- Reporting Views
-- MySQL-compatible SQL
-- =============================================================================
-- Run schema.sql and sample_data.sql before this file.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- v_average_score_per_student
-- Average quiz score per student (across all enrollments).
-- Uses: AVG, JOIN, GROUP BY
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_average_score_per_student;
CREATE VIEW v_average_score_per_student AS
SELECT
    u.id    AS user_id,
    u.name  AS student_name,
    u.email AS student_email,
    COUNT(DISTINCT s.id)     AS total_quiz_attempts,
    ROUND(AVG(s.score), 2)  AS avg_score,
    MAX(s.score)            AS max_score,
    MIN(s.score)            AS min_score
FROM Users u
INNER JOIN Enrollments e ON e.user_id = u.id
INNER JOIN Progress p    ON p.enrollment_id = e.id
INNER JOIN Scores s      ON s.progress_id = p.id
WHERE u.role = 'Student'
GROUP BY u.id, u.name, u.email;

-- -----------------------------------------------------------------------------
-- v_top_performers_per_course
-- Top performers per course: per-student avg score and completion (rank in queries.sql).
-- Uses: AVG, COUNT
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_top_performers_per_course;
CREATE VIEW v_top_performers_per_course AS
SELECT
    c.id    AS course_id,
    c.title AS course_title,
    u.id    AS user_id,
    u.name  AS student_name,
    ROUND(AVG(s.score), 2) AS avg_score,
    COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END) AS completed_modules,
    COUNT(DISTINCT m.id) AS total_modules,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END)
            / NULLIF(COUNT(DISTINCT m.id), 0),
        2
    ) AS completion_pct
FROM Users u
INNER JOIN Enrollments e ON e.user_id = u.id
INNER JOIN Courses c ON c.id = e.course_id
INNER JOIN Modules m ON m.course_id = c.id
LEFT JOIN Progress pr ON pr.enrollment_id = e.id AND pr.module_id = m.id
LEFT JOIN Scores s ON s.progress_id = pr.id
WHERE u.role = 'Student'
GROUP BY u.id, u.name, c.id, c.title, e.id;

-- -----------------------------------------------------------------------------
-- v_course_completion_rate
-- Per-course: total enrollments, completed (100% modules), completion rate %.
-- Uses: COUNT, SUM (of boolean-like), AVG
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_course_completion_rate;
CREATE VIEW v_course_completion_rate AS
SELECT
    c.id    AS course_id,
    c.title AS course_title,
    COUNT(DISTINCT e.id) AS total_enrollments,
    SUM(
        CASE WHEN completed_modules.total_modules = completed_modules.completed_modules THEN 1 ELSE 0 END
    ) AS completed_count,
    ROUND(
        100.0 * SUM(
            CASE WHEN completed_modules.total_modules = completed_modules.completed_modules THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(DISTINCT e.id), 0),
        2
    ) AS completion_rate_pct
FROM Courses c
INNER JOIN Enrollments e ON e.course_id = c.id
INNER JOIN (
    SELECT
        e2.id AS enrollment_id,
        COUNT(DISTINCT m.id) AS total_modules,
        COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END) AS completed_modules
    FROM Enrollments e2
    INNER JOIN Modules m ON m.course_id = e2.course_id
    LEFT JOIN Progress pr ON pr.enrollment_id = e2.id AND pr.module_id = m.id
    GROUP BY e2.id
) AS completed_modules ON completed_modules.enrollment_id = e.id
GROUP BY c.id, c.title;

-- -----------------------------------------------------------------------------
-- v_student_progress_dashboard
-- Per enrollment: student, course, modules completed/total, completion %, avg score.
-- Uses: COUNT, AVG, SUM (implicit in completion)
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_student_progress_dashboard;
CREATE VIEW v_student_progress_dashboard AS
SELECT
    u.id    AS user_id,
    u.name  AS student_name,
    e.id    AS enrollment_id,
    c.id    AS course_id,
    c.title AS course_title,
    e.date_enrolled,
    COUNT(DISTINCT m.id) AS total_modules,
    COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END) AS completed_modules,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END)
            / NULLIF(COUNT(DISTINCT m.id), 0),
        2
    ) AS completion_pct,
    ROUND(AVG(s.score), 2) AS avg_quiz_score,
    COUNT(s.id) AS quiz_attempts
FROM Users u
INNER JOIN Enrollments e ON e.user_id = u.id
INNER JOIN Courses c ON c.id = e.course_id
INNER JOIN Modules m ON m.course_id = c.id
LEFT JOIN Progress pr ON pr.enrollment_id = e.id AND pr.module_id = m.id
LEFT JOIN Scores s ON s.progress_id = pr.id
WHERE u.role = 'Student'
GROUP BY u.id, u.name, e.id, e.date_enrolled, c.id, c.title;

-- -----------------------------------------------------------------------------
-- v_instructor_performance_overview
-- Per instructor: courses taught, total enrollments, avg completion rate, avg score.
-- Uses: AVG, COUNT, SUM
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_instructor_performance_overview;
CREATE VIEW v_instructor_performance_overview AS
SELECT
    u.id    AS instructor_id,
    u.name  AS instructor_name,
    u.email AS instructor_email,
    COUNT(DISTINCT c.id) AS total_courses,
    COUNT(DISTINCT e.id) AS total_enrollments,
    ROUND(AVG(dash.completion_pct), 2) AS avg_completion_pct,
    ROUND(AVG(dash.avg_quiz_score), 2) AS avg_quiz_score_overall,
    SUM(dash.quiz_attempts) AS total_quiz_attempts
FROM Users u
INNER JOIN Courses c ON c.instructor_id = u.id
LEFT JOIN Enrollments e ON e.course_id = c.id
LEFT JOIN (
    SELECT
        e2.course_id,
        e2.id AS enrollment_id,
        ROUND(
            100.0 * COUNT(DISTINCT CASE WHEN pr.completion_status = TRUE THEN pr.module_id END)
                / NULLIF(COUNT(DISTINCT m.id), 0),
            2
        ) AS completion_pct,
        AVG(s.score) AS avg_quiz_score,
        COUNT(s.id) AS quiz_attempts
    FROM Enrollments e2
    INNER JOIN Modules m ON m.course_id = e2.course_id
    LEFT JOIN Progress pr ON pr.enrollment_id = e2.id AND pr.module_id = m.id
    LEFT JOIN Scores s ON s.progress_id = pr.id
    GROUP BY e2.id, e2.course_id
) AS dash ON dash.course_id = c.id AND dash.enrollment_id = e.id
WHERE u.role = 'Instructor'
GROUP BY u.id, u.name, u.email;

-- -----------------------------------------------------------------------------
-- v_student_leaderboard
-- Student ranking leaderboard: rank by average quiz score (global).
-- Uses: AVG, COUNT; ranking can be done in query layer with RANK in MySQL 8+
-- -----------------------------------------------------------------------------
DROP VIEW IF EXISTS v_student_leaderboard;
CREATE VIEW v_student_leaderboard AS
SELECT
    user_id,
    student_name,
    student_email,
    total_quiz_attempts,
    avg_score,
    max_score,
    min_score
FROM v_average_score_per_student
ORDER BY avg_score DESC, user_id;

-- -----------------------------------------------------------------------------
-- End of views
-- -----------------------------------------------------------------------------
