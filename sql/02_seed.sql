-- Sample data for demonstration and testing queries

INSERT INTO Student (first_name, last_name) VALUES
  ('Alice', 'Anderson'),
  ('Bob', 'Smith'),
  ('Carol', 'Quinn'),
  ('Dan', 'Brown');

INSERT INTO Course (code, title) VALUES
  ('CS101', 'Introduction to Databases'),
  ('MATH200', 'Calculus II');

INSERT INTO Enrollment (student_id, course_id) VALUES
  (1, 1), (2, 1), (3, 1), (4, 1),
  (1, 2), (2, 2);

INSERT INTO GradeCategory (course_id, name, weight_percent) VALUES
  (1, 'Homework', 40),
  (1, 'Exams', 60),
  (2, 'Homework', 30),
  (2, 'Exams', 70);

INSERT INTO Assignment (course_id, category_id, name, max_points) VALUES
  (1, 1, 'HW1', 10),
  (1, 1, 'HW2', 10),
  (1, 2, 'Midterm', 100),
  (1, 2, 'Final', 100),
  (2, 3, 'HW1', 20),
  (2, 4, 'Exam1', 50);

-- Scores: enrollment_id follows inserts (CS101: 1–4, MATH200: 5–6)
INSERT INTO Score (enrollment_id, assignment_id, points_earned) VALUES
  (1, 1, 9), (1, 2, 8), (1, 3, 85), (1, 4, 90),
  (2, 1, 7), (2, 2, 9), (2, 3, 72), (2, 4, 78),
  (3, 1, 10), (3, 2, 6), (3, 3, 88), (3, 4, 82),
  (4, 1, 5), (4, 2, 7), (4, 3, 60), (4, 4, 65),
  (5, 5, 18), (5, 6, 45),
  (6, 5, 15), (6, 6, 40);
