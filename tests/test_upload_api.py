import json

import boto3
from moto import mock_aws

from upload_api.handler import lambda_handler


@mock_aws
def test_upload_api_returns_presigned_url(monkeypatch):
    monkeypatch.setenv("UPLOAD_BUCKET", "test-upload-bucket")
    client = boto3.client("s3", region_name="ap-south-1")
    client.create_bucket(
        Bucket="test-upload-bucket",
        CreateBucketConfiguration={"LocationConstraint": "ap-south-1"},
    )
    response = lambda_handler(
        {
            "body": json.dumps(
                {"filename": "photo.png", "content_type": "image/png"}
            )
        },
        None,
    )
    assert response["statusCode"] == 200
    body = json.loads(response["body"])
    assert body["object_key"].startswith("incoming/")
    assert "upload_url" in body


def test_upload_api_rejects_unsupported_type(monkeypatch):
    monkeypatch.setenv("UPLOAD_BUCKET", "unused")
    response = lambda_handler(
        {
            "body": json.dumps(
                {"filename": "x.exe", "content_type": "application/octet-stream"}
            )
        },
        None,
    )
    assert response["statusCode"] == 400
