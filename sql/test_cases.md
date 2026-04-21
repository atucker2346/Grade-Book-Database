# Grade Book Database Test Cases

This document records the SQL command used for each required task, the expected result, and an actual output snapshot from a SQLite run using:

- `sql/01_schema.sql`
- `sql/02_seed.sql`
- `sql/03_show_tables.sql`
- `sql/04_queries_and_updates.sql` (task-specific commands executed independently in the order shown below)

## Task 2 - Create Tables and Insert Values

**Command**

```sql
.read sql/01_schema.sql
.read sql/02_seed.sql
SELECT name
FROM sqlite_master
WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
ORDER BY name;
```

**Expected Result**

- Six tables are created: `Student`, `Course`, `Enrollment`, `GradeCategory`, `Assignment`, `Score`.
- Seed rows are inserted without errors.

**Actual Result Snapshot**

```text
('Assignment',), ('Course',), ('Enrollment',), ('GradeCategory',), ('Score',), ('Student',)
```

## Task 3 - Show Inserted Table Contents

**Command**

```sql
.read sql/03_show_tables.sql
SELECT course_id, department, course_number, title, semester, year, code
FROM Course
ORDER BY course_id;
```

**Expected Result**

- Inserted rows are visible in each table.
- `Course` includes strict attributes: `department`, `course_number`, `semester`, `year`.

**Actual Result Snapshot**

```text
(1, 'CS', 101, 'Introduction to Databases', 'Spring', 2026, 'CS101')
(2, 'MATH', 200, 'Calculus II', 'Spring', 2026, 'MATH200')
```

## Task 4 - Average / Highest / Lowest Score of an Assignment

**Command**

```sql
SELECT
  ROUND(AVG(points_earned), 2) AS avg_score,
  MAX(points_earned) AS highest_score,
  MIN(points_earned) AS lowest_score
FROM Score
WHERE assignment_id = 1;
```

**Expected Result**

- Returns one row with assignment statistics.

**Actual Result Snapshot**

```text
(7.75, 10.0, 5.0)
```

## Task 5 - List All Students in a Given Course

**Command**

```sql
SELECT
  s.student_id, s.first_name, s.last_name
FROM Enrollment e
JOIN Student s ON s.student_id = e.student_id
WHERE e.course_id = 1
ORDER BY s.last_name, s.first_name;
```

**Expected Result**

- Returns all students enrolled in `course_id = 1`.

**Actual Result Snapshot**

```text
(1, 'Alice', 'Anderson')
(4, 'Dan', 'Brown')
(3, 'Carol', 'Quinn')
(2, 'Bob', 'Smith')
```

## Task 6 - List Students in a Course With All Assignment Scores

**Command**

```sql
SELECT
  s.student_id,
  s.first_name,
  s.last_name,
  a.assignment_id,
  a.name AS assignment_name,
  sc.points_earned,
  a.max_points
FROM Enrollment e
JOIN Student s ON s.student_id = e.student_id
JOIN Score sc ON sc.enrollment_id = e.enrollment_id
JOIN Assignment a ON a.assignment_id = sc.assignment_id
WHERE e.course_id = 1 AND a.course_id = 1
ORDER BY s.last_name, s.first_name, a.assignment_id;
```

**Expected Result**

- Returns one row per student-assignment score for the specified course.

**Actual Result Snapshot**

```text
(1, 'Alice', 'Anderson', 1, 'HW1', 9.0, 10.0)
(1, 'Alice', 'Anderson', 2, 'HW2', 8.0, 10.0)
(1, 'Alice', 'Anderson', 3, 'Midterm', 85.0, 100.0)
(1, 'Alice', 'Anderson', 4, 'Final', 90.0, 100.0)
(4, 'Dan', 'Brown', 1, 'HW1', 5.0, 10.0)
(4, 'Dan', 'Brown', 2, 'HW2', 7.0, 10.0)
(4, 'Dan', 'Brown', 3, 'Midterm', 60.0, 100.0)
(4, 'Dan', 'Brown', 4, 'Final', 65.0, 100.0)
(3, 'Carol', 'Quinn', 1, 'HW1', 10.0, 10.0)
(3, 'Carol', 'Quinn', 2, 'HW2', 6.0, 10.0)
(3, 'Carol', 'Quinn', 3, 'Midterm', 88.0, 100.0)
(3, 'Carol', 'Quinn', 4, 'Final', 82.0, 100.0)
(2, 'Bob', 'Smith', 1, 'HW1', 7.0, 10.0)
(2, 'Bob', 'Smith', 2, 'HW2', 9.0, 10.0)
(2, 'Bob', 'Smith', 3, 'Midterm', 72.0, 100.0)
(2, 'Bob', 'Smith', 4, 'Final', 78.0, 100.0)
```

## Task 7 - Add an Assignment to a Course

**Command**

```sql
INSERT INTO Assignment (course_id, category_id, name, max_points)
VALUES (1, 1, 'HW3', 10);

INSERT INTO Score (enrollment_id, assignment_id, points_earned)
SELECT e.enrollment_id, (SELECT MAX(assignment_id) FROM Assignment), 0
FROM Enrollment e
WHERE e.course_id = 1;

SELECT assignment_id, course_id, category_id, name, max_points
FROM Assignment
WHERE course_id = 1
ORDER BY assignment_id;
```

**Expected Result**

- New assignment `HW3` is created for course 1.
- Score rows are added for all enrolled students in course 1.

**Actual Result Snapshot**

```text
(1, 1, 1, 'HW1', 10.0)
(2, 1, 1, 'HW2', 10.0)
(3, 1, 2, 'Midterm', 100.0)
(4, 1, 2, 'Final', 100.0)
(7, 1, 1, 'HW3', 10.0)
```

## Task 8 - Change Category Percentages for a Course

**Command**

```sql
UPDATE GradeCategory
SET weight_percent = 35
WHERE course_id = 1 AND name = 'Homework';

UPDATE GradeCategory
SET weight_percent = 65
WHERE course_id = 1 AND name = 'Exams';

SELECT course_id, name, weight_percent
FROM GradeCategory
WHERE course_id = 1
ORDER BY category_id;
```

**Expected Result**

- Updated percentages for course 1 categories are reflected in table output.

**Actual Result Snapshot**

```text
(1, 'Homework', 35.0)
(1, 'Exams', 65.0)
```

## Task 9 - Add 2 Points to Each Student on an Assignment

**Command**

```sql
UPDATE Score
SET points_earned = MIN(
  points_earned + 2,
  (SELECT max_points FROM Assignment WHERE assignment_id = Score.assignment_id)
)
WHERE assignment_id = 1;

SELECT e.enrollment_id, s.last_name, sc.assignment_id, sc.points_earned
FROM Score sc
JOIN Enrollment e ON e.enrollment_id = sc.enrollment_id
JOIN Student s ON s.student_id = e.student_id
WHERE sc.assignment_id = 1
ORDER BY e.enrollment_id;
```

**Expected Result**

- Every student score on assignment 1 increases by 2, capped at max points.

**Actual Result Snapshot**

```text
(1, 'Anderson', 1, 10.0)
(2, 'Smith', 1, 9.0)
(3, 'Quinn', 1, 10.0)
(4, 'Brown', 1, 7.0)
```

## Task 10 - Add 2 Points Only for Last Names Containing 'Q'

**Command**

```sql
UPDATE Score
SET points_earned = MIN(
  Score.points_earned + 2,
  (SELECT max_points FROM Assignment WHERE assignment_id = Score.assignment_id)
)
WHERE assignment_id = 1
  AND enrollment_id IN (
    SELECT e.enrollment_id
    FROM Enrollment e
    JOIN Student s ON s.student_id = e.student_id
    WHERE s.last_name LIKE '%Q%'
  );

SELECT e.enrollment_id, s.last_name, sc.assignment_id, sc.points_earned
FROM Score sc
JOIN Enrollment e ON e.enrollment_id = sc.enrollment_id
JOIN Student s ON s.student_id = e.student_id
WHERE sc.assignment_id = 1
ORDER BY e.enrollment_id;
```

**Expected Result**

- Only students with last names containing `Q` are increased by 2 points (still capped).

**Actual Result Snapshot**

```text
(1, 'Anderson', 1, 10.0)
(2, 'Smith', 1, 9.0)
(3, 'Quinn', 1, 10.0)
(4, 'Brown', 1, 7.0)
```

Note: In this seeded data, `Quinn` was already at max for assignment 1 after Task 9, so the score remains 10.

## Task 11 - Compute the Grade for a Student

**Command**

```sql
WITH cat AS (
  SELECT
    gc.category_id,
    gc.name AS category_name,
    gc.weight_percent,
    SUM(sc.points_earned) AS earned,
    SUM(a.max_points) AS possible
  FROM Score sc
  JOIN Assignment a ON a.assignment_id = sc.assignment_id
  JOIN GradeCategory gc ON gc.category_id = a.category_id
  JOIN Enrollment en ON en.enrollment_id = sc.enrollment_id
  WHERE sc.enrollment_id = 1
    AND gc.course_id = en.course_id
  GROUP BY gc.category_id, gc.name, gc.weight_percent
)
SELECT
  ROUND(SUM((earned * 1.0 / NULLIF(possible, 0)) * 100.0 * (weight_percent / 100.0)), 2) AS final_percent
FROM cat
WHERE possible > 0;
```

**Expected Result**

- Returns one weighted final percentage for the chosen enrollment.

**Actual Result Snapshot**

```text
(77.88)
```

## Task 12 - Compute Grade With Lowest Score in Category Dropped

**Command**

```sql
WITH per AS (
  SELECT
    sc.enrollment_id,
    a.category_id,
    sc.assignment_id,
    sc.points_earned,
    a.max_points,
    COUNT(*) OVER (PARTITION BY sc.enrollment_id, a.category_id) AS cnt_in_cat,
    ROW_NUMBER() OVER (
      PARTITION BY sc.enrollment_id, a.category_id
      ORDER BY (sc.points_earned * 1.0 / a.max_points) ASC, sc.assignment_id ASC
    ) AS worst_rn
  FROM Score sc
  JOIN Assignment a ON a.assignment_id = sc.assignment_id
  JOIN Enrollment en ON en.enrollment_id = sc.enrollment_id
  WHERE sc.enrollment_id = 1
    AND a.course_id = en.course_id
),
kept AS (
  SELECT enrollment_id, category_id, assignment_id, points_earned, max_points
  FROM per
  WHERE cnt_in_cat = 1 OR worst_rn > 1
),
cat AS (
  SELECT
    gc.category_id,
    gc.name AS category_name,
    gc.weight_percent,
    SUM(k.points_earned) AS earned,
    SUM(a.max_points) AS possible
  FROM kept k
  JOIN Assignment a ON a.assignment_id = k.assignment_id
  JOIN GradeCategory gc ON gc.category_id = a.category_id
  JOIN Enrollment en ON en.enrollment_id = k.enrollment_id
  WHERE gc.course_id = en.course_id
  GROUP BY gc.category_id, gc.name, gc.weight_percent
)
SELECT
  ROUND(SUM((earned * 1.0 / NULLIF(possible, 0)) * 100.0 * (weight_percent / 100.0)), 2) AS final_percent_with_drop
FROM cat
WHERE possible > 0;
```

**Expected Result**

- Returns one weighted final percentage after dropping the lowest score in each category.

**Actual Result Snapshot**

```text
(90.0)
```
