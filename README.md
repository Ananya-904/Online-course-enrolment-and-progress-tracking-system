# Online Course Enrolment and Progress Tracking System

## System Overview

This project implements a **relational database system** for an e-learning platform that supports:

- **Course registration** — Students enroll in courses; each enrollment is tracked.
- **Progress tracking** — Module completion and quiz scores are recorded per enrollment.
- **Performance analytics** — Reports for top performers, completion rates, and student rankings.

The implementation is **MySQL-compatible**, uses **Third Normal Form (3NF)**, and includes:

- Full schema with constraints, indexes, and referential integrity
- Stored procedures for enrollment and progress updates
- Reporting views for administrative insights
- Sample data for testing
- Performance report queries

---

## ER Diagram (Textual Description)

```
                    +----------+
                    |  Users   |
                    | id (PK)  |
                    | name     |
                    | email    |
                    | role     |
                    +----+-----+
                         |
         +---------------+---------------+
         |               |               |
         | instructor_id | user_id       | (Admin/Student/Instructor)
         v               v               v
   +----------+   +-------------+   (roles in same table)
   | Courses  |   | Enrollments |
   | id (PK)  |   | id (PK)     |
   | title    |<--+ user_id     |
   | instr_id |   | course_id   |
   +----+-----+   | date_enrolled
        |         +------+------+
        |                |
        | course_id      | enrollment_id
        v                v
   +---------+     +----------+
   | Modules |     | Progress |
   | id (PK) |<----+ id (PK)  |
   | course  |     | enroll_id|
   | name    |     | module_id|
   | order   |     | status   |
   +----+----+     | compl_dt|
        |         +----+-----+
        |              |
        | module_id    | progress_id
        v              v
   +---------+    +--------+
   | Quizzes |    | Scores |
   | id (PK) |    | id(PK) |
   | module  |    | prog_id|
   | max_sc  |    | score  |
   +---------+    | date   |
                  +--------+
```

**Relationships:**

- **Users** - One user can be Instructor of many **Courses**; one user can have many **Enrollments** (as Student).
- **Courses** - One course has many **Modules** (ordered); one course has many **Enrollments**.
- **Enrollments** - One enrollment (user + course) has many **Progress** rows (one per module).
- **Modules** - One module has one **Quiz**; one module appears in many **Progress** rows.
- **Progress** - One progress row (enrollment + module) can have many **Scores** (quiz attempts).

---

## Table Relationships

| Table        | Primary Key | Foreign Keys                    | Notes                              |
|-------------|-------------|----------------------------------|------------------------------------|
| Users       | id          | -                                | role: Student / Instructor / Admin |
| Courses     | id          | instructor_id → Users(id)        | One instructor per course          |
| Modules     | id          | course_id → Courses(id)          | module_order per course            |
| Enrollments | id          | user_id → Users(id), course_id → Courses(id) | Unique (user_id, course_id) |
| Progress    | id          | enrollment_id → Enrollments(id), module_id → Modules(id) | Unique (enrollment_id, module_id) |
| Quizzes     | id          | module_id → Modules(id)          | One quiz per module                |
| Scores      | id          | progress_id → Progress(id)       | Multiple attempts per progress     |

Referential integrity is enforced with `ON DELETE CASCADE` or `ON DELETE RESTRICT` as appropriate.

---

## File Structure

```
online-course-db/
├── schema.sql      # CREATE TABLE statements (constraints, indexes, comments)
├── procedures.sql  # Stored procedures (EnrollStudent, UpdateModuleProgress, RecordQuizScore, GenerateStudentReport)
├── sample_data.sql # Test data for all tables
├── views.sql       # Reporting views
├── queries.sql     # Performance reports and core queries
└── README.md       # This documentation
```

---

## Stored Procedure Descriptions

| Procedure             | Inputs                    | Action |
|-----------------------|---------------------------|--------|
| **EnrollStudent**     | `p_user_id`, `p_course_id` | Validates user and course, checks duplicate enrollment, inserts one row into `Enrollments` with `date_enrolled = CURDATE()`. |
| **UpdateModuleProgress** | `p_enrollment_id`, `p_module_id`, `p_status` | Inserts or updates a row in `Progress`; sets `completion_date` when `p_status` is TRUE. |
| **RecordQuizScore**   | `p_progress_id`, `p_score` | Validates progress and score ≥ 0, inserts one row into `Scores` with current timestamp. |
| **GenerateStudentReport** | (none)                 | Returns a result set: per student per course, total/completed modules, completion %, avg quiz score, quiz attempt count. |

**Example calls:**

```sql
CALL EnrollStudent(3, 5);
CALL UpdateModuleProgress(1, 1, TRUE);
CALL RecordQuizScore(1, 85.50);
CALL GenerateStudentReport();
```

---

## Views for Reporting

| View                             | Purpose |
|----------------------------------|--------|
| **v_average_score_per_student**  | Per-student: total quiz attempts, AVG/MAX/MIN score. |
| **v_top_performers_per_course**  | Per course per enrollment: student, avg score, completed/total modules, completion %. |
| **v_course_completion_rate**     | Per course: total enrollments, count completed (100% modules), completion rate %. |
| **v_student_progress_dashboard** | Per enrollment: student, course, date_enrolled, completed/total modules, completion %, avg quiz score, quiz attempts. |
| **v_instructor_performance_overview** | Per instructor: course count, enrollment count, avg completion %, avg quiz score, total quiz attempts. |
| **v_student_leaderboard**        | Same as v_average_score_per_student, ordered by avg_score DESC (for leaderboard). |

---

## Example Queries and Outputs

### 1. Top 5 students by average score

```sql
SELECT user_id, student_name, avg_score
FROM v_average_score_per_student
ORDER BY avg_score DESC
LIMIT 5;
```

**Example output (with sample data):**

| user_id | student_name | avg_score |
|--------|--------------|-----------|
| 5      | Eve Brown    | 90.50     |
| 3      | Carol White  | 88.00     |
| 1      | Alice Johnson| 85.17     |
| 2      | Bob Smith    | 86.00     |
| 4      | David Lee    | 76.00     |

*(Exact order depends on sample data.)*

### 2. Most popular courses

```sql
SELECT c.title, COUNT(e.id) AS enrollment_count
FROM Courses c
LEFT JOIN Enrollments e ON e.course_id = c.id
GROUP BY c.id, c.title
ORDER BY enrollment_count DESC;
```

**Example output:**

| title                     | enrollment_count |
|---------------------------|------------------|
| Introduction to SQL       | 5                |
| Database Design           | 2                |
| Python for Data Science   | 2                |
| ...                       | ...              |

### 3. Course completion percentage

```sql
SELECT course_title, total_enrollments, completion_rate_pct
FROM v_course_completion_rate;
```

### 4. Student performance report (procedure)

```sql
CALL GenerateStudentReport();
```

Returns one row per enrollment with: `user_id`, `student_name`, `course_title`, `total_modules`, `completed_modules`, `completion_pct`, `avg_quiz_score`, `quiz_attempts`.

---

## Instructions to Run the Database

### Prerequisites

- **MySQL** 5.7+ or **MariaDB** 10.2+ (MySQL-compatible).

### Option A: Command line

```bash
# Create database
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS online_course_db;"
mysql -u root -p online_course_db < schema.sql
mysql -u root -p online_course_db < procedures.sql
mysql -u root -p online_course_db < sample_data.sql
mysql -u root -p online_course_db < views.sql
```

Then run report queries:

```bash
mysql -u root -p online_course_db < queries.sql
```

### Option B: MySQL client (source)

```sql
CREATE DATABASE IF NOT EXISTS online_course_db;
USE online_course_db;

SOURCE schema.sql;
SOURCE procedures.sql;
SOURCE sample_data.sql;
SOURCE views.sql;
-- Then run individual queries from queries.sql or CALL GenerateStudentReport();
```

### Option C: Full reinstall (drop and recreate)

1. In `schema.sql`, uncomment the `DROP TABLE` block at the top (and `SET FOREIGN_KEY_CHECKS`).
2. Run in order: `schema.sql` → `procedures.sql` → `sample_data.sql` → `views.sql`.
3. Run `queries.sql` or individual statements as needed.

### Verify

```sql
USE online_course_db;
SHOW TABLES;
SELECT COUNT(*) FROM Users;
SELECT COUNT(*) FROM Enrollments;
CALL GenerateStudentReport();
```

---

## Design Notes

- **3NF:** Attributes depend only on the primary key; no transitive dependencies in normalized tables.
- **Indexes:** Placed on foreign keys, unique columns (e.g. email), and common filter/sort columns (role, date_enrolled, completion_status).
- **Constraints:** UNIQUE on (user_id, course_id) for Enrollments and (enrollment_id, module_id) for Progress; CHECK on Scores(score >= 0).
- **Character set:** `utf8mb4` for full Unicode support.

---

## License and Use

This is production-quality educational SQL for an online course enrolment and progress tracking system. Use and adapt as needed for your environment.
