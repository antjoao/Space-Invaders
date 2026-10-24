from flask import Flask, request, jsonify
import sqlite3
import os

app = Flask(__name__)
DB_PATH = os.path.join(os.path.dirname(__file__), "scores.db")

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            score INTEGER NOT NULL,
            date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()

@app.route("/scores", methods=["GET"])
def get_scores():
    conn = sqlite3.connect(DB_PATH)
    rows = conn.execute(
        "SELECT name, score, date FROM scores ORDER BY score DESC LIMIT 10"
    ).fetchall()
    conn.close()
    return jsonify([
        {"name": r[0], "score": r[1], "date": r[2]} for r in rows
    ])

@app.route("/scores", methods=["POST"])
def post_score():
    data = request.get_json(silent=True)
    if not data or "name" not in data or "score" not in data:
        return jsonify({"error": "invalid payload"}), 400

    name = str(data["name"])[:20].strip() or "ANON"
    try:
        score = int(data["score"])
    except (ValueError, TypeError):
        return jsonify({"error": "invalid score"}), 400

    if score < 0:
        return jsonify({"error": "negative score"}), 400

    conn = sqlite3.connect(DB_PATH)
    conn.execute("INSERT INTO scores (name, score) VALUES (?, ?)", (name, score))
    conn.commit()
    conn.close()
    return jsonify({"ok": True, "name": name, "score": score})

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    init_db()
    print("[server] Listening on http://127.0.0.1:8080")
    app.run(host="127.0.0.1", port=8080, debug=False)