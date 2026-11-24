from __future__ import annotations

import json
import logging
import os
from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError

from image_processor.processor import process_image

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
sns = boto3.client("sns")

OUTPUT_BUCKET = os.environ["OUTPUT_BUCKET"]
TABLE_NAME = os.environ["TABLE_NAME"]
TOPIC_ARN = os.getenv("TOPIC_ARN", "")
table = dynamodb.Table(TABLE_NAME)


def _notify(message: dict) -> None:
    if TOPIC_ARN:
        sns.publish(TopicArn=TOPIC_ARN, Message=json.dumps(message))


def _process_record(record: dict) -> None:
    body = json.loads(record["body"])
    # S3 notifications may be wrapped in an SNS envelope in some integrations.
    if "Message" in body:
        body = json.loads(body["Message"])
    for event_record in body.get("Records", []):
        if event_record.get("eventSource") != "aws:s3":
            continue
        bucket = event_record["s3"]["bucket"]["name"]
        key = unquote_plus(event_record["s3"]["object"]["key"])
        version_id = event_record["s3"]["object"].get("versionId", "null")
        if key.startswith("processed/"):
            logger.info("Skipping generated output object: s3://%s/%s", bucket, key)
            continue

        metadata = s3.head_object(Bucket=bucket, Key=key)
        if metadata.get("ContentLength", 0) > int(os.getenv("MAX_INPUT_BYTES", "10485760")):
            raise ValueError("Image exceeds configured input size limit")
        source = s3.get_object(Bucket=bucket, Key=key)
        data = source["Body"].read()
        output, content_type = process_image(data, os.getenv("WATERMARK_TEXT"))
        output_key = f"processed/{key.rsplit('.', 1)[0]}.jpg"
        s3.put_object(
            Bucket=OUTPUT_BUCKET,
            Key=output_key,
            Body=output,
            ContentType=content_type,
            ServerSideEncryption="AES256",
            Metadata={"source-bucket": bucket, "source-key": key},
        )
        table.update_item(
            Key={"object_id": f"{bucket}/{key}#{version_id}"},
            UpdateExpression="SET #s=:s, output_bucket=:b, output_key=:k, content_type=:c",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={
                ":s": "COMPLETED",
                ":b": OUTPUT_BUCKET,
                ":k": output_key,
                ":c": content_type,
            },
        )
        _notify({"status": "COMPLETED", "source": f"s3://{bucket}/{key}",
                 "output": f"s3://{OUTPUT_BUCKET}/{output_key}"})
        logger.info("Processed s3://%s/%s -> s3://%s/%s", bucket, key, OUTPUT_BUCKET, output_key)


def lambda_handler(event: dict, context: object) -> dict:
    failures = []
    for record in event.get("Records", []):
        message_id = record.get("messageId")
        try:
            _process_record(record)
        except (ClientError, ValueError, KeyError, json.JSONDecodeError):
            logger.exception("Failed SQS message %s", message_id)
            failures.append({"itemIdentifier": message_id})
            _notify({"status": "FAILED", "messageId": message_id})
    return {"batchItemFailures": failures}
