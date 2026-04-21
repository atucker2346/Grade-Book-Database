-- Sample data for demonstration and testing queries

INSERT INTO Student (first_name, last_name) VALUES
  ('Alice', 'Anderson'),
  ('Bob', 'Smith'),
  ('Carol', 'Quinn'),
  ('Dan', 'Brown'),
  ('Eve', 'Johnson'),
  ('Frank', 'Miller'),
  ('Grace', 'Lee'),
  ('Henry', 'Garcia'),
  ('Ivy', 'Nguyen'),
  ('Jack', 'Diaz');

INSERT INTO Course (department, course_number, title, semester, year) VALUES
  ('CS', 101, 'Introduction to Databases', 'Spring', 2026),
  ('MATH', 200, 'Calculus II', 'Spring', 2026),
  ('BIO', 150, 'General Biology', 'Spring', 2026),
  ('ENG', 210, 'Technical Writing', 'Spring', 2026);

INSERT INTO Enrollment (student_id, course_id) VALUES
  (1, 1), (2, 1), (3, 1), (4, 1),
  (1, 2), (2, 2),
  (5, 1), (6, 1), (7, 1),
  (3, 2), (8, 2),
  (5, 3), (6, 3), (8, 3), (9, 3),
  (2, 4), (7, 4), (10, 4);

INSERT INTO GradeCategory (course_id, name, weight_percent) VALUES
  (1, 'Homework', 40),
  (1, 'Exams', 60),
  (2, 'Homework', 30),
  (2, 'Exams', 70),
  (3, 'Labs', 35),
  (3, 'Exams', 50),
  (3, 'Participation', 15),
  (4, 'Homework', 25),
  (4, 'Project', 35),
  (4, 'Exams', 40);

INSERT INTO Assignment (course_id, category_id, name, max_points) VALUES
  (1, 1, 'HW1', 10),
  (1, 1, 'HW2', 10),
  (1, 2, 'Midterm', 100),
  (1, 2, 'Final', 100),
  (2, 3, 'HW1', 20),
  (2, 4, 'Exam1', 50);

-- Additional assignments for new courses
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 3, category_id, 'Lab1', 25 FROM GradeCategory WHERE course_id = 3 AND name = 'Labs';
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 3, category_id, 'Lab2', 25 FROM GradeCategory WHERE course_id = 3 AND name = 'Labs';
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 3, category_id, 'Midterm', 100 FROM GradeCategory WHERE course_id = 3 AND name = 'Exams';
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 3, category_id, 'Participation1', 10 FROM GradeCategory WHERE course_id = 3 AND name = 'Participation';

INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 4, category_id, 'HW1', 20 FROM GradeCategory WHERE course_id = 4 AND name = 'Homework';
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 4, category_id, 'Project1', 100 FROM GradeCategory WHERE course_id = 4 AND name = 'Project';
INSERT INTO Assignment (course_id, category_id, name, max_points)
SELECT 4, category_id, 'FinalExam', 100 FROM GradeCategory WHERE course_id = 4 AND name = 'Exams';

-- Scores: enrollment_id follows inserts (CS101: 1–4, MATH200: 5–6)
INSERT INTO Score (enrollment_id, assignment_id, points_earned) VALUES
  (1, 1, 9), (1, 2, 8), (1, 3, 85), (1, 4, 90),
  (2, 1, 7), (2, 2, 9), (2, 3, 72), (2, 4, 78),
  (3, 1, 10), (3, 2, 6), (3, 3, 88), (3, 4, 82),
  (4, 1, 5), (4, 2, 7), (4, 3, 60), (4, 4, 65),
  (5, 5, 18), (5, 6, 45),
  (6, 5, 15), (6, 6, 40),
  (7, 1, 8), (7, 2, 9), (7, 3, 92), (7, 4, 95),
  (8, 1, 6), (8, 2, 7), (8, 3, 70), (8, 4, 73),
  (9, 1, 9), (9, 2, 8), (9, 3, 84), (9, 4, 88),
  (10, 5, 19), (10, 6, 47),
  (11, 5, 16), (11, 6, 42),
  (12, 7, 22), (12, 8, 20), (12, 9, 90), (12, 10, 9),
  (13, 7, 18), (13, 8, 19), (13, 9, 75), (13, 10, 8),
  (14, 7, 21), (14, 8, 23), (14, 9, 82), (14, 10, 10),
  (15, 7, 24), (15, 8, 22), (15, 9, 88), (15, 10, 9),
  (16, 11, 17), (16, 12, 91), (16, 13, 87),
  (17, 11, 15), (17, 12, 84), (17, 13, 79),
  (18, 11, 18), (18, 12, 95), (18, 13, 90);
