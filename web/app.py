from flask import Flask, render_template, redirect, url_for, session

app = Flask(__name__)
app.secret_key = "shoplite-dev-secret-key"

# Initial product catalogue (part of the monolith)
PRODUCTS = [
    {"id": 1, "name": "Wireless Headphones", "price": 59.99, "emoji": "🎧"},
    {"id": 2, "name": "Mechanical Keyboard", "price": 89.99, "emoji": "⌨️"},
    {"id": 3, "name": "Smart Watch", "price": 129.99, "emoji": "⌚"},
    {"id": 4, "name": "USB-C Hub", "price": 34.99, "emoji": "🔌"},
]


@app.route("/")
def index():
    cart = session.get("cart", [])
    return render_template("index.html", products=PRODUCTS, cart_count=len(cart))


@app.route("/cart/add/<int:product_id>", methods=["POST"])
def add_to_cart(product_id):
    if any(p["id"] == product_id for p in PRODUCTS):
        cart = session.get("cart", [])
        cart.append(product_id)
        session["cart"] = cart

    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)