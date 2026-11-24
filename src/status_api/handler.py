from __future__ import annotations

import json
import os
from urllib.parse import unquote_plus

import boto3

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event: dict, context: object) -> dict:
    key = (event.get("queryStringParameters") or {}).get("key")
    if not key or not key.startswith("incoming/") or ".." in key:
        return _response(400, {"error": "A valid incoming/ object key is required"})
    table = dynamodb.Table(os.environ["TABLE_NAME"])
    result = table.get_item(Key={"object_id": f"{os.environ['UPLOAD_BUCKET']}/{unquote_plus(key)}"})
    item = result.get("Item")
    if not item:
        return _response(404, {"status": "NOT_FOUND"})
    return _response(200, item)


def _response(status: int, body: dict) -> dict:
    return {"statusCode": status, "headers": {"content-type": "application/json"},
            "body": json.dumps(body, default=str)}
