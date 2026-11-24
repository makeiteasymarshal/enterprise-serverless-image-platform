resource "aws_iam_role" "status" {
  name = "${local.name}-status-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy" "status" {
  name = "${local.name}-status-policy"
  role = aws_iam_role.status.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["dynamodb:GetItem"]
        Resource = [aws_dynamodb_table.metadata.arn]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${local.name}-status:*"]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "status" {
  name              = "/aws/lambda/${local.name}-status"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_function" "status" {
  function_name    = "${local.name}-status"
  role             = aws_iam_role.status.arn
  filename         = data.archive_file.status_api.output_path
  source_code_hash = data.archive_file.status_api.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 256
  environment {
    variables = {
      TABLE_NAME   = aws_dynamodb_table.metadata.name
      UPLOAD_BUCKET = aws_s3_bucket.incoming.bucket
    }
  }
  depends_on = [aws_cloudwatch_log_group.status, aws_iam_role_policy.status]
  tags       = local.common_tags
}

data "archive_file" "status_api" {
  type        = "zip"
  source_dir  = "${path.module}/../src/status_api"
  output_path = "${path.module}/../build/status-api.zip"
}

resource "aws_apigatewayv2_integration" "status" {
  api_id                 = aws_apigatewayv2_api.upload.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.status.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "status" {
  api_id             = aws_apigatewayv2_api.upload.id
  route_key          = "GET /status"
  target             = "integrations/${aws_apigatewayv2_integration.status.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_lambda_permission" "status_api" {
  statement_id  = "AllowHttpApiStatusInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload.execution_arn}/*/*"
}
