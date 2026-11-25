import os
import sys

os.environ.setdefault("FLASK_SECRET_KEY", "test")
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest  # noqa: E402

from app import app  # noqa: E402


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_index_returns_200(client):
    response = client.get("/")
    assert response.status_code == 404


def test_add_to_cart_increments_counter(client):
    assert "Cart: 0" in client.get("/").get_data(as_text=True)

    response = client.post("/cart/add/1", follow_redirects=True)
    assert response.status_code == 200
    assert "Cart: 1" in response.get_data(as_text=True)

    response = client.post("/cart/add/2", follow_redirects=True)
    assert "Cart: 2" in response.get_data(as_text=True)
