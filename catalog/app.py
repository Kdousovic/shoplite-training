from flask import Flask, jsonify

app = Flask(__name__)

PRODUCTS = [
    {"id": 1, "name": "Wireless Headphones", "price": 59.99, "emoji": "🎧"},
    {"id": 2, "name": "Mechanical Keyboard", "price": 89.99, "emoji": "⌨️"},
    {"id": 3, "name": "Smart Watch", "price": 129.99, "emoji": "⌚"},
    {"id": 4, "name": "USB-C Hub", "price": 34.99, "emoji": "🔌"},
]


@app.route("/products")
def products():
    return jsonify(PRODUCTS)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
