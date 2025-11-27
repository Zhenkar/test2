import mysql.connector
from mysql.connector import pooling

# Connection Pool (Better for production + gunicorn)
connection_pool = pooling.MySQLConnectionPool(
    pool_name="mypool",
    pool_size=10,
    host="localhost",
    user="newuser",
    password="Zhenkar@123",
    database="notes_app",
    charset="utf8mb4"  # avoid unsupported collations
)

def get_connection():
    try:
        return connection_pool.get_connection()
    except Exception as e:
        print("❌ Database connection error:", e)
        return None
