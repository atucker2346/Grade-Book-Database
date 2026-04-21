-- Grade Book Database — DDL
-- Aligns with a typical ER design: Student, Course, Enrollment, GradeCategory, Assignment, Score

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS Score;
DROP TABLE IF EXISTS Assignment;
DROP TABLE IF EXISTS GradeCategory;
DROP TABLE IF EXISTS Enrollment;
DROP TABLE IF EXISTS Student;
DROP TABLE IF EXISTS Course;

CREATE TABLE Student (
  student_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name   TEXT NOT NULL,
  last_name    TEXT NOT NULL
);

CREATE TABLE Course (
  course_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  department     TEXT NOT NULL,
  course_number  INTEGER NOT NULL,
  title          TEXT NOT NULL,
  semester       TEXT NOT NULL,
  year           INTEGER NOT NULL,
  code           TEXT GENERATED ALWAYS AS (department || course_number) VIRTUAL,
  UNIQUE (department, course_number, semester, year)
);

CREATE TABLE Enrollment (
  enrollment_id INTEGER PRIMARY KEY AUTOINCREMENT,
  student_id    INTEGER NOT NULL REFERENCES Student (student_id) ON DELETE CASCADE,
  course_id     INTEGER NOT NULL REFERENCES Course (course_id) ON DELETE CASCADE,
  UNIQUE (student_id, course_id)
);

-- Weighted categories per course (e.g. Homework 40%, Exams 60%). Should sum to 100 per course.
CREATE TABLE GradeCategory (
  category_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id      INTEGER NOT NULL REFERENCES Course (course_id) ON DELETE CASCADE,
  name           TEXT NOT NULL,
  weight_percent REAL NOT NULL CHECK (weight_percent >= 0 AND weight_percent <= 100),
  UNIQUE (course_id, name)
);

CREATE TABLE Assignment (
  assignment_id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id     INTEGER NOT NULL REFERENCES Course (course_id) ON DELETE CASCADE,
  category_id   INTEGER NOT NULL REFERENCES GradeCategory (category_id) ON DELETE CASCADE,
  name          TEXT NOT NULL,
  max_points    REAL NOT NULL CHECK (max_points > 0),
  UNIQUE (course_id, name)
);

CREATE TABLE Score (
  score_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  enrollment_id INTEGER NOT NULL REFERENCES Enrollment (enrollment_id) ON DELETE CASCADE,
  assignment_id INTEGER NOT NULL REFERENCES Assignment (assignment_id) ON DELETE CASCADE,
  points_earned REAL NOT NULL DEFAULT 0 CHECK (points_earned >= 0),
  UNIQUE (enrollment_id, assignment_id)
);
