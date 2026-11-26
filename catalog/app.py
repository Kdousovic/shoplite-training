import json
import logging
import os

from flask import Flask, has_request_context, jsonify, request

app = Flask(__name__)
VERSION = os.environ.get("APP_VERSION", "unknown")


class JsonFormatter(logging.Formatter):
    def format(self, record):
        entry = {
            "level": record.levelname,
            "route": request.path if has_request_context() else None,
            "version": VERSION,
            "message": record.getMessage(),
        }
        if record.exc_info:
            entry["exception"] = self.formatException(record.exc_info)
        return json.dumps(entry)


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
app.logger.handlers = [handler]
app.logger.setLevel(logging.INFO)
app.logger.propagate = False


@app.after_request
def log_request(response):
    level = logging.ERROR if response.status_code >= 500 else logging.INFO
    app.logger.log(level, "%s %s", request.method, response.status_code)
    return response


@app.route("/boom")
def boom():
    # Lab only: triggers a 500 to test logs and alarms
    raise RuntimeError("boom")


PRODUCTS = [
    {"id": 1, "name": "Wireless Headphones", "price": 59.99, "emoji": "🎧"},
    {"id": 2, "name": "Mechanical Keyboard", "price": 89.99, "emoji": "⌨️"},
    {"id": 3, "name": "Smart Watch", "price": 129.99, "emoji": "⌚"},
    {"id": 4, "name": "USB-C Hub", "price": 34.99, "emoji": "🔌"},
    {"id": 5, "name": "Bluetooth Speaker", "price": 44.99, "emoji": "🔊"},

]


@app.route("/products")
def products():
    page_size = int(os.environ.get("PAGE_SIZE", "10"))
    return jsonify(PRODUCTS[:page_size])


if __name__ == "__main__":
    # Must listen on all interfaces inside the container
    app.run(host="0.0.0.0", port=8080)  # nosec B104
