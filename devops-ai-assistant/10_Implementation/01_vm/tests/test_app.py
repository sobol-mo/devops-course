from app import app

def test_health_endpoint():
    # Створюємо тестового клієнта Flask
    client = app.test_client()
    # Робимо запит до /health
    response = client.get("/health")
    # Перевіряємо, чи повернувся код 200 (OK) та правильний JSON
    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}