from flask import Flask, jsonify
import os

app = Flask(__name__)

@app.route("/")
def index():
    return "<h1>My Training App</h1><p>Status: running</p>"

@app.route("/health")
def health():
    return jsonify({"status": "ok"})

if __name__ == '__main__':
    # Слухаємо всі інтерфейси (0.0.0.0), а не тільки 127.0.0.1
    app.run(host='0.0.0.0', port=5000)
