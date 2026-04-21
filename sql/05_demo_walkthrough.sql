.headers on
.mode column

SELECT 'DEMO START: Grade Book Database' AS step;

SELECT 'Task 3: Show table counts' AS step;
SELECT 'Student' AS table_name, COUNT(*) AS row_count FROM Student
UNION ALL
SELECT 'Course', COUNT(*) FROM Course
UNION ALL
SELECT 'Enrollment', COUNT(*) FROM Enrollment
UNION ALL
SELECT 'GradeCategory', COUNT(*) FROM GradeCategory
UNION ALL
SELECT 'Assignment', COUNT(*) FROM Assignment
UNION ALL
SELECT 'Score', COUNT(*) FROM Score;

SELECT 'Task 4: Assignment stats (assignment_id=1)' AS step;
SELECT
  ROUND(AVG(points_earned), 2) AS avg_score,
  MAX(points_earned) AS highest_score,
  MIN(points_earned) AS lowest_score
FROM Score
WHERE assignment_id = 1;

SELECT 'Task 5: Students in CS101 (course_id=1)' AS step;
SELECT
  s.student_id,
  s.first_name,
  s.last_name
FROM Enrollment e
JOIN Student s ON s.student_id = e.student_id
WHERE e.course_id = 1
ORDER BY s.last_name, s.first_name;

SELECT 'Task 6: Students + all scores in CS101' AS step;
SELECT
  s.student_id,
  s.first_name,
  s.last_name,
  a.name AS assignment_name,
  sc.points_earned,
  a.max_points
FROM Enrollment e
JOIN Student s ON s.student_id = e.student_id
JOIN Score sc ON sc.enrollment_id = e.enrollment_id
JOIN Assignment a ON a.assignment_id = sc.assignment_id
WHERE e.course_id = 1
  AND a.course_id = 1
ORDER BY s.last_name, s.first_name, a.assignment_id;

SELECT 'Task 7: Add HW3 to CS101 + initialize scores' AS step;
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

SELECT 'Task 8: Change category weights to 35/65 for CS101' AS step;
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

SELECT 'Task 9: Add 2 points to everyone on assignment 1 (capped)' AS step;
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

SELECT 'Task 10: Add 2 points for last name containing Q on assignment 1' AS step;
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

SELECT 'Task 11: Compute weighted final grade (enrollment_id=1)' AS step;
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

SELECT 'Task 12: Final grade with lowest score dropped per category (enrollment_id=1)' AS step;
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

SELECT 'DEMO END' AS step;
