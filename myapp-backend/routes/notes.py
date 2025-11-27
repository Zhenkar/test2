from flask import Blueprint, request, jsonify
from db import get_connection
from werkzeug.security import generate_password_hash, check_password_hash

notes_bp = Blueprint("notes_bp", __name__)

# ------------------ User Registration ------------------
@notes_bp.post("/register")
def register():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()

    hashed_pw = generate_password_hash(data["password"])

    try:
        cursor.execute(
            "INSERT INTO users (username, email, password) VALUES (%s, %s, %s)",
            (data["username"], data["email"], hashed_pw)
        )
        conn.commit()
        return jsonify({"message": "User registered successfully"}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ------------------ User Login ------------------
@notes_bp.post("/login")
def login():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM users WHERE email=%s",
        (data["email"],)
    )
    user = cursor.fetchone()

    if user and check_password_hash(user["password"], data["password"]):
        return jsonify({
            "message": "Login successful",
            "user": {
                "id": user["id"],
                "username": user["username"],
                "email": user["email"]
            }
        })
    return jsonify({"error": "Invalid credentials"}), 401

# ------------------ Create Note ------------------
@notes_bp.post("/notes")
def create_note():
    data = request.json
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO notes (user_id, title, content, color, pinned) VALUES (%s, %s, %s, %s, %s)",
        (
            data["user_id"],
            data.get("title", ""),
            data.get("content", ""),
            data.get("color", "#fff"),
            data.get("pinned", False)
        )
    )
    conn.commit()
    return jsonify({"message": "Note added"}), 201

# ------------------ Get Notes for User ------------------
@notes_bp.get("/notes/<int:user_id>")
def get_user_notes(user_id):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT * FROM notes WHERE user_id=%s ORDER BY pinned DESC, created_at DESC",
        (user_id,)
    )
    notes = cursor.fetchall()
    return jsonify(notes)

# ------------------ Delete Note ------------------
@notes_bp.delete("/notes/<int:note_id>")
def delete_note(note_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM notes WHERE id=%s", (note_id,))
    conn.commit()
    return jsonify({"message": "Note deleted"})
