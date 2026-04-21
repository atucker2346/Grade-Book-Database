import sqlite3
from pathlib import Path


def format_table(headers: list[str], rows: list[tuple]) -> str:
    if not headers:
        return ""
    widths = [len(str(h)) for h in headers]
    for row in rows:
        for i, cell in enumerate(row):
            widths[i] = max(widths[i], len(str(cell)))

    header_line = " | ".join(str(h).ljust(widths[i]) for i, h in enumerate(headers))
    divider = "-+-".join("-" * widths[i] for i in range(len(headers)))
    body = [
        " | ".join(str(cell).ljust(widths[i]) for i, cell in enumerate(row))
        for row in rows
    ]
    return "\n".join([header_line, divider, *body]) if body else "\n".join([header_line, divider, "(no rows)"])


def short_sql_label(stmt: str, limit: int = 90) -> str:
    one_line = " ".join(stmt.split())
    return (one_line[: limit - 3] + "...") if len(one_line) > limit else one_line


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

    print("GRADE BOOK DATABASE DEMO")
    print("=" * 60)
    print("Source: sql/05_demo_walkthrough.sql")
    print("=" * 60)

    # sqlite3 dot-commands are CLI-specific; remove them for Python sqlite execution.
    filtered_lines = []
    for line in demo_sql.splitlines():
        if line.strip().startswith("."):
            continue
        filtered_lines.append(line)

    statements = [s.strip() for s in "\n".join(filtered_lines).split(";") if s.strip()]
    for idx, stmt in enumerate(statements, start=1):
        try:
            cur = conn.execute(stmt)
            if cur.description:
                rows = cur.fetchall()
                print(f"\n[{idx:02}] {short_sql_label(stmt)}")
                headers = [d[0] for d in cur.description]
                print(format_table(headers, rows))
        except sqlite3.Error as exc:
            print(f"\n[{idx:02}] {short_sql_label(stmt)}")
            print(f"ERROR: {exc}")
            raise

    conn.commit()
    conn.close()

    print("\n" + "=" * 60)
    print("Demo complete.")
    print(f"Database file: {db_path}")


if __name__ == "__main__":
    main()
