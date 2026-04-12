-- =============================================================================
-- Parameterized examples: replace :assignment_id, :course_id, :enrollment_id
-- In sqlite3 CLI:  .param set :assignment_id 1
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Average / highest / lowest score on an assignment
-- -----------------------------------------------------------------------------
-- Example: assignment_id = 1 (HW1 in CS101)

SELECT
  AVG(points_earned) AS avg_score,
  MAX(points_earned) AS highest_score,
  MIN(points_earned) AS lowest_score
FROM Score
WHERE assignment_id = 1;

-- -----------------------------------------------------------------------------
-- All students enrolled in a given course
-- -----------------------------------------------------------------------------
-- Example: course_id = 1 (CS101)

SELECT
  s.student_id,
  s.first_name,
  s.last_name
FROM Enrollment e
JOIN Student s ON s.student_id = e.student_id
WHERE e.course_id = 1
ORDER BY s.last_name, s.first_name;

-- -----------------------------------------------------------------------------
-- All students in a course and every assignment score (long format)
-- -----------------------------------------------------------------------------
-- Example: course_id = 1

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
WHERE e.course_id = 1
  AND a.course_id = 1
ORDER BY s.last_name, s.first_name, a.assignment_id;

-- -----------------------------------------------------------------------------
-- Add an assignment to a course
-- -----------------------------------------------------------------------------
-- Example: new homework in CS101 under Homework category (category_id 1)

INSERT INTO Assignment (course_id, category_id, name, max_points)
VALUES (1, 1, 'HW3', 10);

-- Create zero scores for all enrollments in that course (optional but typical)
INSERT INTO Score (enrollment_id, assignment_id, points_earned)
SELECT e.enrollment_id, (SELECT MAX(assignment_id) FROM Assignment), 0
FROM Enrollment e
WHERE e.course_id = 1;

-- -----------------------------------------------------------------------------
-- Change category percentages for a course (must still sum to 100 in real use)
-- -----------------------------------------------------------------------------

UPDATE GradeCategory
SET weight_percent = 35
WHERE course_id = 1 AND name = 'Homework';

UPDATE GradeCategory
SET weight_percent = 65
WHERE course_id = 1 AND name = 'Exams';

-- -----------------------------------------------------------------------------
-- Add 2 points to every student on one assignment (cap at max_points)
-- -----------------------------------------------------------------------------
-- Example: assignment_id = 1

UPDATE Score
SET points_earned = MIN(
  points_earned + 2,
  (SELECT max_points FROM Assignment WHERE assignment_id = Score.assignment_id)
)
WHERE assignment_id = 1;

-- -----------------------------------------------------------------------------
-- Add 2 points only for students whose last name contains 'Q'
-- -----------------------------------------------------------------------------
-- Example: same assignment_id = 1

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

-- -----------------------------------------------------------------------------
-- Course grade for one student: weighted average by category
-- Category % = (sum of points earned) / (sum of max points) * 100
-- Final = SUM(category_percent * weight_percent / 100)
-- -----------------------------------------------------------------------------
-- Use enrollment_id (one student in one course). Example: enrollment_id = 1

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

-- Detailed breakdown for the same enrollment:

WITH cat AS (
  SELECT
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
  category_name,
  weight_percent,
  earned,
  possible,
  ROUND((earned * 1.0 / possible) * 100.0, 2) AS category_percent
FROM cat
WHERE possible > 0;

-- -----------------------------------------------------------------------------
-- Same grade, but drop the lowest score within each category (by % of max)
-- If a category has only one scored assignment, nothing is dropped there.
-- -----------------------------------------------------------------------------
-- Example: enrollment_id = 1

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
