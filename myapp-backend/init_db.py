import os
import mysql.connector
from mysql.connector import errorcode
from pathlib import Path
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def initialize_database():
    """
    Connects to the MySQL server (no DB), creates database if missing,
    then executes statements from schema.sql (idempotent recommended).
    DB connection config is read from environment variables:
      DB_HOST, DB_USER, DB_PASSWORD, DB_PORT (optional)
    """

    db_host = os.environ.get("DB_HOST", "localhost")
    db_user = os.environ.get("DB_USER", "newuser")
    db_password = os.environ.get("DB_PASSWORD", "")
    db_port = int(os.environ.get("DB_PORT", 3306))
    db_name = os.environ.get("DB_NAME", "notes_app")

    if not db_password:
        logger.warning("DB_PASSWORD is empty — make sure this is intentional.")

    # Connect to MySQL server WITHOUT specifying database
    try:
        connection = mysql.connector.connect(
            host=db_host,
            user=db_user,
            password=db_password,
            port=db_port,
            charset="utf8mb4",
            autocommit=False
        )
    except mysql.connector.Error as err:
        logger.exception("Could not connect to MySQL server.")
        raise

    cursor = connection.cursor()

    try:
        logger.info("Creating database (if not exists): %s", db_name)
        cursor.execute(
            f"CREATE DATABASE IF NOT EXISTS `{db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
        )
        connection.commit()

        cursor.execute(f"USE `{db_name}`;")

        # Resolve schema.sql relative to this file (so running from other CWD works)
        schema_path = Path(__file__).parent / "schema.sql"
        if not schema_path.exists():
            raise FileNotFoundError(f"schema.sql not found at {schema_path}")

        sql_text = schema_path.read_text(encoding="utf-8")

        # Basic split on semicolon to get statements. Keep statements sane (strip whitespace).
        statements = [stmt.strip() for stmt in sql_text.split(";") if stmt.strip()]

        logger.info("Executing %d SQL statements from schema.sql", len(statements))

        for stmt in statements:
            try:
                cursor.execute(stmt)
            except mysql.connector.Error as e:
                # If an error is OK (like "table exists"), we skip but log as info/warn.
                # Adjust behavior if you want errors to stop initialization.
                logger.warning("Skipped statement due to error: %s — statement preview: %.100s", e, stmt)
        connection.commit()

        logger.info("✅ Database and tables initialized successfully")
    finally:
        try:
            cursor.close()
        except Exception:
            pass
        try:
            connection.close()
        except Exception:
            pass


if __name__ == "__main__":
    initialize_database()
