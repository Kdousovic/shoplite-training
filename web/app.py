import json
import os
import urllib.request

from flask import Flask, render_template, redirect, url_for, session

app = Flask(__name__)
app.secret_key = os.environ["FLASK_SECRET_KEY"]

# Initial product catalogue (part of the monolith)
PRODUCTS = [
    {"id": 1, "name": "Wireless Headphones", "price": 59.99, "emoji": "🎧"},
    {"id": 2, "name": "Mechanical Keyboard", "price": 89.99, "emoji": "⌨️"},
    {"id": 3, "name": "Smart Watch", "price": 129.99, "emoji": "⌚"},
    {"id": 4, "name": "USB-C Hubbb", "price": 34.99, "emoji": "🔌"},
]


def get_products():
    # Use catalog API if configured, else fall back to local list
    url = os.environ.get("CATALOG_API_URL")
    if not url:
        return PRODUCTS
    try:
        products_url = url.rstrip("/") + "/products"
        # URL from our own env var, not user input
        with urllib.request.urlopen(products_url, timeout=3) as r:  # nosec
            return json.load(r)
    except Exception:
        return PRODUCTS


def get_reviews(product_id):
    # None when the reviews API is unset or unreachable: section hidden
    url = os.environ.get("REVIEWS_API_URL")
    if not url:
        return None
    try:
        # URL from our own env var, not user input
        with urllib.request.urlopen(  # nosec
            f"{url.rstrip('/')}/reviews?productId={product_id}", timeout=2
        ) as r:
            return json.load(r)
    except Exception:
        return None


@app.route("/")
def index():
    cart = session.get("cart", [])
    products = get_products()
    reviews = {p["id"]: get_reviews(p["id"]) for p in products}
    return render_template(
        "index.html", products=products, reviews=reviews, cart_count=len(cart)
    )


@app.route("/cart/add/<int:product_id>", methods=["POST"])
def add_to_cart(product_id):
    if any(p["id"] == product_id for p in get_products()):
        cart = session.get("cart", [])
        cart.append(product_id)
        session["cart"] = cart

    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=os.environ.get("FLASK_DEBUG") == "1",
    )
