# Grade Book Database

## How to Run

This project uses SQLite to create and manage a grade book database.

### 1. Create the database
Open a terminal in the project folder and run:


sqlite3 gradebook.db


### 2. Run the SQL scripts (in order)
Inside the SQLite prompt, execute:


.read sql/01_schema.sql
.read sql/02_seed.sql
.read sql/03_show_tables.sql
.read sql/04_queries_and_updates.sql


### 3. Verify the database
You can check that everything loaded correctly by running:


.tables
SELECT * FROM Student;
SELECT * FROM Course;


### 4. Exit SQLite

.quit


## Notes
- Make sure SQLite is installed on your system
- Run the scripts in the correct order to avoid errors
- The seed file adds sample data for testing queries