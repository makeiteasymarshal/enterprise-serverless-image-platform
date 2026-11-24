import boto3
from moto import mock_aws

from status_api.handler import lambda_handler


@mock_aws
def test_status_returns_not_found(monkeypatch):
    monkeypatch.setenv("TABLE_NAME", "metadata")
    monkeypatch.setenv("UPLOAD_BUCKET", "uploads")
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    dynamodb.create_table(
        TableName="metadata",
        KeySchema=[{"AttributeName": "object_id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "object_id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
    response = lambda_handler({"queryStringParameters": {"key": "incoming/nope.png"}}, None)
    assert response["statusCode"] == 404
