from __future__ import annotations

import json
import os
import re
import uuid

import boto3

ALLOWED_TYPES = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp"}
SAFE_NAME = re.compile(r"[^A-Za-z0-9._-]+")


def lambda_handler(event: dict, context: object) -> dict:
    try:
        body = json.loads(event.get("body") or "{}")
        filename = str(body.get("filename", "upload")).split("/")[-1].split("\\")[-1]
        content_type = body.get("content_type")
        if content_type not in ALLOWED_TYPES:
            return _response(
                400,
                {"error": "content_type must be image/jpeg, image/png, or image/webp"},
            )
        safe_name = SAFE_NAME.sub("-", filename)[:80].strip(".-") or "upload"
        key = f"incoming/{uuid.uuid4().hex}-{safe_name}"
        url = boto3.client("s3").generate_presigned_url(
            "put_object",
            Params={"Bucket": os.environ["UPLOAD_BUCKET"], "Key": key, "ContentType": content_type},
            ExpiresIn=300,
        )
        return _response(
            200,
            {
                "upload_url": url,
                "object_key": key,
                "required_headers": {"Content-Type": content_type},
                "expires_in_seconds": 300,
            },
        )
    except (ValueError, TypeError):
        return _response(400, {"error": "Invalid JSON request"})


def _response(status: int, body: dict) -> dict:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(body),
    }
