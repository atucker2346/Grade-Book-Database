import sqlite3
from pathlib import Path


ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "gradebook_demo.db"


def reset_db() -> sqlite3.Connection:
    if DB_PATH.exists():
        DB_PATH.unlink()
    conn = sqlite3.connect(DB_PATH)
    schema_sql = (ROOT / "sql" / "01_schema.sql").read_text(encoding="utf-8")
    seed_sql = (ROOT / "sql" / "02_seed.sql").read_text(encoding="utf-8")
    conn.executescript(schema_sql)
    conn.executescript(seed_sql)
    conn.commit()
    return conn


def print_rows(title: str, cur: sqlite3.Cursor) -> None:
    print(f"\n=== {title} ===")
    cols = [d[0] for d in cur.description] if cur.description else []
    if cols:
        print(" | ".join(cols))
        print("-" * (len(" | ".join(cols))))
    rows = cur.fetchall()
    for r in rows:
        print(" | ".join(str(x) for x in r))
    if not rows:
        print("(no rows)")


def ask_int(prompt: str, default: int) -> int:
    raw = input(f"{prompt} [{default}]: ").strip()
    if not raw:
        return default
    return int(raw)


def list_reference_data(conn: sqlite3.Connection) -> None:
    print_rows(
        "Courses",
        conn.execute(
            "SELECT course_id, department, course_number, title, semester, year FROM Course ORDER BY course_id"
        ),
    )
    print_rows(
        "Assignments",
        conn.execute(
            "SELECT assignment_id, course_id, category_id, name, max_points FROM Assignment ORDER BY assignment_id"
        ),
    )
    print_rows(
        "Enrollments",
        conn.execute(
            "SELECT enrollment_id, student_id, course_id FROM Enrollment ORDER BY enrollment_id"
        ),
    )


def task4(conn: sqlite3.Connection) -> None:
    assignment_id = ask_int("Assignment ID for stats", 1)
    cur = conn.execute(
        """
        SELECT ROUND(AVG(points_earned),2) AS avg_score,
               MAX(points_earned) AS highest_score,
               MIN(points_earned) AS lowest_score
        FROM Score
        WHERE assignment_id = ?
        """,
        (assignment_id,),
    )
    print_rows("Task 4: Assignment stats", cur)


def task5(conn: sqlite3.Connection) -> None:
    course_id = ask_int("Course ID", 1)
    cur = conn.execute(
        """
        SELECT s.student_id, s.first_name, s.last_name
        FROM Enrollment e
        JOIN Student s ON s.student_id = e.student_id
        WHERE e.course_id = ?
        ORDER BY s.last_name, s.first_name
        """,
        (course_id,),
    )
    print_rows("Task 5: Students in course", cur)


def task6(conn: sqlite3.Connection) -> None:
    course_id = ask_int("Course ID", 1)
    cur = conn.execute(
        """
        SELECT s.student_id, s.first_name, s.last_name, a.assignment_id, a.name, sc.points_earned, a.max_points
        FROM Enrollment e
        JOIN Student s ON s.student_id = e.student_id
        JOIN Score sc ON sc.enrollment_id = e.enrollment_id
        JOIN Assignment a ON a.assignment_id = sc.assignment_id
        WHERE e.course_id = ? AND a.course_id = ?
        ORDER BY s.last_name, s.first_name, a.assignment_id
        """,
        (course_id, course_id),
    )
    print_rows("Task 6: Students + all scores", cur)


def task7(conn: sqlite3.Connection) -> None:
    course_id = ask_int("Course ID", 1)
    category_id = ask_int("Category ID", 1)
    name = input("New assignment name [HW3]: ").strip() or "HW3"
    max_points = ask_int("Max points", 10)
    conn.execute(
        "INSERT INTO Assignment (course_id, category_id, name, max_points) VALUES (?, ?, ?, ?)",
        (course_id, category_id, name, max_points),
    )
    new_id = conn.execute("SELECT MAX(assignment_id) FROM Assignment").fetchone()[0]
    conn.execute(
        """
        INSERT INTO Score (enrollment_id, assignment_id, points_earned)
        SELECT enrollment_id, ?, 0
        FROM Enrollment
        WHERE course_id = ?
        """,
        (new_id, course_id),
    )
    conn.commit()
    print(f"\nAdded assignment '{name}' with assignment_id={new_id}.")


def task8(conn: sqlite3.Connection) -> None:
    course_id = ask_int("Course ID", 1)
    hw_weight = ask_int("Homework weight", 35)
    ex_weight = ask_int("Exams weight", 65)
    conn.execute(
        "UPDATE GradeCategory SET weight_percent = ? WHERE course_id = ? AND name = 'Homework'",
        (hw_weight, course_id),
    )
    conn.execute(
        "UPDATE GradeCategory SET weight_percent = ? WHERE course_id = ? AND name = 'Exams'",
        (ex_weight, course_id),
    )
    conn.commit()
    cur = conn.execute(
        "SELECT category_id, name, weight_percent FROM GradeCategory WHERE course_id = ? ORDER BY category_id",
        (course_id,),
    )
    print_rows("Task 8: Updated category weights", cur)


def task9(conn: sqlite3.Connection) -> None:
    assignment_id = ask_int("Assignment ID", 1)
    conn.execute(
        """
        UPDATE Score
        SET points_earned = MIN(
          points_earned + 2,
          (SELECT max_points FROM Assignment WHERE assignment_id = Score.assignment_id)
        )
        WHERE assignment_id = ?
        """,
        (assignment_id,),
    )
    conn.commit()
    cur = conn.execute(
        """
        SELECT e.enrollment_id, s.last_name, sc.assignment_id, sc.points_earned
        FROM Score sc
        JOIN Enrollment e ON e.enrollment_id = sc.enrollment_id
        JOIN Student s ON s.student_id = e.student_id
        WHERE sc.assignment_id = ?
        ORDER BY e.enrollment_id
        """,
        (assignment_id,),
    )
    print_rows("Task 9: +2 points all students", cur)


def task10(conn: sqlite3.Connection) -> None:
    assignment_id = ask_int("Assignment ID", 1)
    conn.execute(
        """
        UPDATE Score
        SET points_earned = MIN(
          points_earned + 2,
          (SELECT max_points FROM Assignment WHERE assignment_id = Score.assignment_id)
        )
        WHERE assignment_id = ?
          AND enrollment_id IN (
            SELECT e.enrollment_id
            FROM Enrollment e
            JOIN Student s ON s.student_id = e.student_id
            WHERE s.last_name LIKE '%Q%'
          )
        """,
        (assignment_id,),
    )
    conn.commit()
    cur = conn.execute(
        """
        SELECT e.enrollment_id, s.last_name, sc.assignment_id, sc.points_earned
        FROM Score sc
        JOIN Enrollment e ON e.enrollment_id = sc.enrollment_id
        JOIN Student s ON s.student_id = e.student_id
        WHERE sc.assignment_id = ?
        ORDER BY e.enrollment_id
        """,
        (assignment_id,),
    )
    print_rows("Task 10: +2 points only names with Q", cur)


def task11(conn: sqlite3.Connection) -> None:
    enrollment_id = ask_int("Enrollment ID", 1)
    cur = conn.execute(
        """
        WITH cat AS (
          SELECT gc.category_id, gc.name AS category_name, gc.weight_percent,
                 SUM(sc.points_earned) AS earned, SUM(a.max_points) AS possible
          FROM Score sc
          JOIN Assignment a ON a.assignment_id = sc.assignment_id
          JOIN GradeCategory gc ON gc.category_id = a.category_id
          JOIN Enrollment en ON en.enrollment_id = sc.enrollment_id
          WHERE sc.enrollment_id = ?
            AND gc.course_id = en.course_id
          GROUP BY gc.category_id, gc.name, gc.weight_percent
        )
        SELECT ROUND(SUM((earned * 1.0 / NULLIF(possible, 0)) * 100.0 * (weight_percent / 100.0)), 2) AS final_percent
        FROM cat
        WHERE possible > 0
        """,
        (enrollment_id,),
    )
    print_rows("Task 11: Final grade", cur)


def task12(conn: sqlite3.Connection) -> None:
    enrollment_id = ask_int("Enrollment ID", 1)
    cur = conn.execute(
        """
        WITH per AS (
          SELECT sc.enrollment_id, a.category_id, sc.assignment_id, sc.points_earned, a.max_points,
                 COUNT(*) OVER (PARTITION BY sc.enrollment_id, a.category_id) AS cnt_in_cat,
                 ROW_NUMBER() OVER (
                   PARTITION BY sc.enrollment_id, a.category_id
                   ORDER BY (sc.points_earned * 1.0 / a.max_points) ASC, sc.assignment_id ASC
                 ) AS worst_rn
          FROM Score sc
          JOIN Assignment a ON a.assignment_id = sc.assignment_id
          JOIN Enrollment en ON en.enrollment_id = sc.enrollment_id
          WHERE sc.enrollment_id = ?
            AND a.course_id = en.course_id
        ),
        kept AS (
          SELECT enrollment_id, category_id, assignment_id, points_earned, max_points
          FROM per
          WHERE cnt_in_cat = 1 OR worst_rn > 1
        ),
        cat AS (
          SELECT gc.category_id, gc.name AS category_name, gc.weight_percent,
                 SUM(k.points_earned) AS earned, SUM(a.max_points) AS possible
          FROM kept k
          JOIN Assignment a ON a.assignment_id = k.assignment_id
          JOIN GradeCategory gc ON gc.category_id = a.category_id
          JOIN Enrollment en ON en.enrollment_id = k.enrollment_id
          WHERE gc.course_id = en.course_id
          GROUP BY gc.category_id, gc.name, gc.weight_percent
        )
        SELECT ROUND(SUM((earned * 1.0 / NULLIF(possible, 0)) * 100.0 * (weight_percent / 100.0)), 2) AS final_percent_with_drop
        FROM cat
        WHERE possible > 0
        """,
        (enrollment_id,),
    )
    print_rows("Task 12: Final grade with drop", cur)


def main() -> None:
    conn = reset_db()
    print("Interactive Grade Book Demo")
    print(f"Using database: {DB_PATH}")
    print("Type a menu number and press Enter.\n")

    actions = {
        "1": ("Show reference data (courses/assignments/enrollments)", list_reference_data),
        "2": ("Task 4: Assignment stats", task4),
        "3": ("Task 5: Students in course", task5),
        "4": ("Task 6: Students + all scores in course", task6),
        "5": ("Task 7: Add assignment", task7),
        "6": ("Task 8: Change category percentages", task8),
        "7": ("Task 9: +2 points all students for assignment", task9),
        "8": ("Task 10: +2 points only last name contains Q", task10),
        "9": ("Task 11: Compute student grade", task11),
        "10": ("Task 12: Compute grade with lowest dropped", task12),
        "11": ("Reset database to original seed", None),
        "0": ("Exit", None),
    }

    while True:
        print("\nMenu")
        for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "0"]:
            print(f"  {key}. {actions[key][0]}")
        try:
            choice = input("\nChoose option: ").strip()
        except EOFError:
            conn.close()
            print("\nInput closed. Exiting demo.")
            return

        if choice == "0":
            conn.close()
            print("Good luck with your demo.")
            return
        if choice == "11":
            conn.close()
            conn = reset_db()
            print("Database reset complete.")
            continue
        if choice in actions and actions[choice][1] is not None:
            try:
                actions[choice][1](conn)
            except Exception as exc:
                print(f"Error: {exc}")
        else:
            print("Invalid option. Try again.")


if __name__ == "__main__":
    main()
