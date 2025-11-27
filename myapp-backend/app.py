from flask import Flask
from flask_cors import CORS
from routes.notes import notes_bp
from init_db import initialize_database

app = Flask(__name__)
CORS(app)

# ---- RUN SCHEMA BEFORE STARTING APP ----
try:
    initialize_database()
except Exception as e:
    print("⚠️ Warning: Database initialization failed:", e)

# ---- ROUTES ----
app.register_blueprint(notes_bp, url_prefix="/")

if __name__ == "__main__":
    # Use host=0.0.0.0 for AWS EC2
    app.run(debug=True, host="0.0.0.0", port=5000)
