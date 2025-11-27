from flask import Flask
from flask_cors import CORS
from routes.notes import notes_bp
from init_db import initialize_database

from dotenv import load_dotenv
load_dotenv()  # <-- loads .env automatically

import sys
import logging

app = Flask(__name__)
CORS(app)

# ------------ DATABASE INIT ------------
try:
    initialize_database()
except Exception as e:
    print("⚠️ Database initialization failed:", e)
    sys.exit(1)

app.register_blueprint(notes_bp, url_prefix="/")

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
