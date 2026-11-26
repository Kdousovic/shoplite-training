import functools
import json
import logging
import os
import time
import uuid
from decimal import Decimal

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def logged(func):
    @functools.wraps(func)
    def wrapper(event, context):
        # With LogFormat JSON, Lambda adds the "extra" keys to the JSON line
        fields = {"route": "/reviews", "version": context.function_version}
        try:
            resp = func(event, context)
        except Exception:
            logger.exception("unhandled error", extra=fields)
            raise
        code = resp["statusCode"]
        level = logging.ERROR if code >= 500 else logging.INFO
        logger.log(level, "status %s", code, extra=fields)
        return resp

    return wrapper


def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=lambda o: int(o) if isinstance(o, Decimal) else str(o)),
    }


@logged
def get_reviews(event, context):
    product_id = (event.get("queryStringParameters") or {}).get("productId")
    if not product_id:
        return _resp(400, {"error": "productId required"})
    res = table.query(
        KeyConditionExpression=boto3.dynamodb.conditions.Key("productId").eq(product_id)
    )
    return _resp(200, res["Items"])


@logged
def post_review(event, context):
    try:
        data = json.loads(event.get("body") or "{}")
        product_id = str(data["productId"])
        rating = int(data["rating"])
        comment = str(data.get("comment", ""))
    except (KeyError, ValueError, TypeError):
        return _resp(400, {"error": "productId and integer rating required"})
    if not 1 <= rating <= 5:
        return _resp(400, {"error": "rating must be 1-5"})
    item = {
        "productId": product_id,
        "reviewId": f"{int(time.time() * 1000)}-{uuid.uuid4().hex[:8]}",
        "rating": rating,
        "comment": comment,
    }
    table.put_item(Item=item)
    return _resp(201, item)
