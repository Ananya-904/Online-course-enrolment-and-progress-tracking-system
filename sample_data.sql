-- =============================================================================
-- Online Course Enrolment and Progress Tracking System
-- Sample Data for Testing
-- MySQL-compatible SQL
-- =============================================================================
-- Run schema.sql before this file. Order: Users -> Courses -> Modules ->
-- Enrollments -> Progress -> Quizzes -> Scores.
-- =============================================================================

-- Disable foreign key checks for bulk insert (optional; re-enable after)
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- USERS
-- Mix of Students, Instructors, and Admins
-- -----------------------------------------------------------------------------
INSERT INTO Users (id, name, email, role) VALUES
(1, 'Alice Johnson',   'alice.j@example.com',   'Student'),
(2, 'Bob Smith',       'bob.smith@example.com', 'Student'),
(3, 'Carol White',     'carol.white@example.com', 'Student'),
(4, 'David Lee',       'david.lee@example.com',  'Student'),
(5, 'Eve Brown',       'eve.brown@example.com', 'Student'),
(6, 'Frank Miller',    'frank.m@example.com',   'Instructor'),
(7, 'Grace Taylor',    'grace.t@example.com',   'Instructor'),
(8, 'Henry Davis',     'henry.d@example.com',   'Admin');

-- Reset auto-increment if using fixed IDs
-- ALTER TABLE Users AUTO_INCREMENT = 9;

-- -----------------------------------------------------------------------------
-- COURSES
-- instructor_id 6 and 7
-- -----------------------------------------------------------------------------
INSERT INTO Courses (id, title, description, instructor_id) VALUES
(1, 'Introduction to SQL',           'Learn SQL fundamentals and queries.', 6),
(2, 'Database Design',               'Normalization, ER modeling, and schema design.', 6),
(3, 'Python for Data Science',       'Python, pandas, and basic analytics.', 7),
(4, 'Web Development Basics',        'HTML, CSS, and JavaScript essentials.', 7),
(5, 'Machine Learning Fundamentals', 'Supervised learning and evaluation.', 7);

-- -----------------------------------------------------------------------------
-- MODULES
-- Per course; module_order 1, 2, 3...
-- -----------------------------------------------------------------------------
INSERT INTO Modules (id, course_id, module_name, module_order) VALUES
-- Course 1: Introduction to SQL
(1,  1, 'SELECT and WHERE',        1),
(2,  1, 'JOINs',                   2),
(3,  1, 'Aggregation and GROUP BY', 3),
(4,  1, 'Subqueries',              4),
-- Course 2: Database Design
(5,  2, 'ER Diagrams',             1),
(6,  2, 'Normalization',           2),
(7,  2, 'Indexes and Performance', 3),
-- Course 3: Python for Data Science
(8,  3, 'Python Basics',           1),
(9,  3, 'Pandas',                  2),
(10, 3, 'Visualization',           3),
-- Course 4: Web Development
(11, 4, 'HTML',                    1),
(12, 4, 'CSS',                     2),
(13, 4, 'JavaScript',              3),
-- Course 5: ML Fundamentals
(14, 5, 'Linear Regression',       1),
(15, 5, 'Classification',         2),
(16, 5, 'Model Evaluation',        3);

-- -----------------------------------------------------------------------------
-- ENROLLMENTS
-- Students 1–5 in various courses
-- -----------------------------------------------------------------------------
INSERT INTO Enrollments (id, user_id, course_id, date_enrolled) VALUES
(1,  1, 1, '2024-01-10'),
(2,  1, 3, '2024-01-15'),
(3,  2, 1, '2024-01-12'),
(4,  2, 2, '2024-02-01'),
(5,  3, 1, '2024-01-20'),
(6,  3, 4, '2024-02-05'),
(7,  4, 1, '2024-01-25'),
(8,  4, 3, '2024-02-10'),
(9,  5, 1, '2024-02-01'),
(10, 5, 2, '2024-02-15'),
(11, 5, 5, '2024-02-20');

-- -----------------------------------------------------------------------------
-- QUIZZES
-- One quiz per module; max_score 100
-- -----------------------------------------------------------------------------
INSERT INTO Quizzes (id, module_id, max_score) VALUES
(1,  1, 100),
(2,  2, 100),
(3,  3, 100),
(4,  4, 100),
(5,  5, 100),
(6,  6, 100),
(7,  7, 100),
(8,  8, 100),
(9,  9, 100),
(10, 10, 100),
(11, 11, 100),
(12, 12, 100),
(13, 13, 100),
(14, 14, 100),
(15, 15, 100),
(16, 16, 100);

-- -----------------------------------------------------------------------------
-- PROGRESS
-- enrollment_id, module_id, completion_status, completion_date
-- Enrollment 1 (Alice, Course 1): completed modules 1,2,3
-- Enrollment 2 (Alice, Course 3): completed 8,9
-- etc.
-- -----------------------------------------------------------------------------
INSERT INTO Progress (id, enrollment_id, module_id, completion_status, completion_date) VALUES
(1,  1, 1, TRUE,  '2024-01-12 10:00:00'),
(2,  1, 2, TRUE,  '2024-01-14 11:00:00'),
(3,  1, 3, TRUE,  '2024-01-16 09:00:00'),
(4,  1, 4, FALSE, NULL),
(5,  2, 8, TRUE,  '2024-01-18 14:00:00'),
(6,  2, 9, TRUE,  '2024-01-20 10:00:00'),
(7,  2, 10, FALSE, NULL),
(8,  3, 1, TRUE,  '2024-01-14 16:00:00'),
(9,  3, 2, TRUE,  '2024-01-17 10:00:00'),
(10, 3, 3, FALSE, NULL),
(11, 3, 4, FALSE, NULL),
(12, 4, 5, TRUE,  '2024-02-03 11:00:00'),
(13, 4, 6, FALSE, NULL),
(14, 4, 7, FALSE, NULL),
(15, 5, 1, TRUE,  '2024-01-22 09:00:00'),
(16, 5, 2, TRUE,  '2024-01-24 14:00:00'),
(17, 5, 3, TRUE,  '2024-01-26 10:00:00'),
(18, 5, 4, TRUE,  '2024-01-28 15:00:00'),
(19, 6, 11, TRUE,  '2024-02-07 12:00:00'),
(20, 6, 12, FALSE, NULL),
(21, 6, 13, FALSE, NULL),
(22, 7, 1, TRUE,  '2024-01-27 11:00:00'),
(23, 7, 2, FALSE, NULL),
(24, 7, 3, FALSE, NULL),
(25, 7, 4, FALSE, NULL),
(26, 8, 8, TRUE,  '2024-02-12 10:00:00'),
(27, 8, 9, FALSE, NULL),
(28, 8, 10, FALSE, NULL),
(29, 9, 1, TRUE,  '2024-02-03 14:00:00'),
(30, 9, 2, TRUE,  '2024-02-05 10:00:00'),
(31, 9, 3, FALSE, NULL),
(32, 9, 4, FALSE, NULL),
(33, 10, 5, TRUE,  '2024-02-17 09:00:00'),
(34, 10, 6, TRUE,  '2024-02-19 11:00:00'),
(35, 10, 7, FALSE, NULL),
(36, 11, 14, TRUE,  '2024-02-22 10:00:00'),
(37, 11, 15, TRUE,  '2024-02-24 14:00:00'),
(38, 11, 16, FALSE, NULL);

-- -----------------------------------------------------------------------------
-- SCORES
-- progress_id -> score, attempt_date
-- Progress 1,2,3 (Alice Course 1 modules 1,2,3); 8,9 (Bob Course 1); etc.
-- -----------------------------------------------------------------------------
INSERT INTO Scores (id, progress_id, score, attempt_date) VALUES
(1,  1,  85.00, '2024-01-12 10:30:00'),
(2,  2,  92.00, '2024-01-14 11:30:00'),
(3,  3,  78.50, '2024-01-16 09:30:00'),
(4,  5,  88.00, '2024-01-18 14:30:00'),
(5,  6,  95.00, '2024-01-20 10:30:00'),
(6,  8,  90.00, '2024-01-14 16:30:00'),
(7,  9,  82.00, '2024-01-17 10:30:00'),
(8,  12, 75.00, '2024-02-03 11:30:00'),
(9,  15, 88.00, '2024-01-22 09:30:00'),
(10, 16, 94.00, '2024-01-24 14:30:00'),
(11, 17, 91.00, '2024-01-26 10:30:00'),
(12, 18, 87.00, '2024-01-28 15:30:00'),
(13, 19, 70.00, '2024-02-07 12:30:00'),
(14, 22, 72.00, '2024-01-27 11:30:00'),
(15, 26, 80.00, '2024-02-12 10:30:00'),
(16, 29, 96.00, '2024-02-03 14:30:00'),
(17, 30, 89.00, '2024-02-05 10:30:00'),
(18, 33, 84.00, '2024-02-17 09:30:00'),
(19, 34, 91.00, '2024-02-19 11:30:00'),
(20, 36, 93.00, '2024-02-22 10:30:00'),
(21, 37, 88.00, '2024-02-24 14:30:00');

SET FOREIGN_KEY_CHECKS = 1;

-- -----------------------------------------------------------------------------
-- End of sample data
-- -----------------------------------------------------------------------------
