import sqlite3
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parent
    db_path = root / "gradebook.db"

    if db_path.exists():
        db_path.unlink()

    conn = sqlite3.connect(db_path)

    schema_sql = (root / "sql" / "01_schema.sql").read_text(encoding="utf-8")
    seed_sql = (root / "sql" / "02_seed.sql").read_text(encoding="utf-8")
    demo_sql = (root / "sql" / "05_demo_walkthrough.sql").read_text(encoding="utf-8")

    conn.executescript(schema_sql)
    conn.executescript(seed_sql)

    print("Running demo from sql/05_demo_walkthrough.sql")
    print("-" * 60)

    # sqlite3 dot-commands are CLI-specific; remove them for Python sqlite execution.
    filtered_lines = []
    for line in demo_sql.splitlines():
        if line.strip().startswith("."):
            continue
        filtered_lines.append(line)

    statements = [s.strip() for s in "\n".join(filtered_lines).split(";") if s.strip()]
    for stmt in statements:
        try:
            cur = conn.execute(stmt)
            if cur.description:
                rows = cur.fetchall()
                print(f"\nSQL> {stmt};")
                for row in rows:
                    print(row)
        except sqlite3.Error as exc:
            print(f"\nSQL> {stmt};")
            print(f"ERROR: {exc}")
            raise

    conn.commit()
    conn.close()

    print("\nDemo complete.")
    print(f"Database file: {db_path}")


if __name__ == "__main__":
    main()
