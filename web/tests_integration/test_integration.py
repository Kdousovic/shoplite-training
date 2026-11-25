import os

import requests

BASE_URL = os.environ["BASE_URL"].rstrip("/")


def test_home_returns_200():
    r = requests.get(BASE_URL + "/", timeout=10)
    assert r.status_code == 200
    assert "ShopLite" in r.text


def test_add_to_cart():
    s = requests.Session()
    r = s.post(BASE_URL + "/cart/add/1", timeout=10)
    assert r.status_code == 200
    assert "Cart: 1" in r.text


def test_reviews_section_displayed():
    r = requests.get(BASE_URL + "/", timeout=10)
    assert r.status_code == 200
    assert 'class="reviews"' in r.text
