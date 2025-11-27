import mysql.connector

def initialize_database():
    # Step 1: Connect to MySQL server without specifying a database
    connection = mysql.connector.connect(
        host="localhost",
        user="newuser",
        password="password123",
        charset="utf8mb4"
    )
    cursor = connection.cursor()

    # Step 2: Create database if it doesn't exist
    cursor.execute("CREATE DATABASE IF NOT EXISTS notes_app CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;")
    connection.commit()

    # Step 3: Use the database
    cursor.execute("USE notes_app;")

    # Step 4: Read schema.sql and execute each statement
    with open("schema.sql", "r") as f:
        sql_statements = f.read()

    statements = [stmt.strip() for stmt in sql_statements.split(";") if stmt.strip()]

    for stmt in statements:
        try:
            cursor.execute(stmt)
        except mysql.connector.Error as e:
            print(f"⚠️ Skipped statement due to error: {e}")

    connection.commit()
    cursor.close()
    connection.close()

    print("✅ Database and tables initialized successfully")


if __name__ == "__main__":
    initialize_database()
