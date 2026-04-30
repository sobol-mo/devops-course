from flask import Flask, jsonify
import os

# Ініціалізація Flask додатку
app = Flask(__name__)

@app.route("/")
def index():
    # Головна сторінка з коротким повідомленням про стан сервісу
    return "<h1>My Training App</h1><p>Status: running</p>"

@app.route("/health")
def health():
    # Простий health endpoint для перевірки працездатності
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    # Порт береться зі змінної середовища, а за замовчуванням використовується 5000
    port = int(os.environ.get("PORT", 5000))
    # Додаток слухає лише localhost усередині VM
    app.run(host="127.0.0.1", port=port)
