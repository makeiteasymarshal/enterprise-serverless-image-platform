provider "aws" {
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  name          = "${var.project_name}-${random_id.suffix.hex}"
  common_tags   = { Project = var.project_name, ManagedBy = "Terraform", Environment = "pilot" }
  processor_zip = "${path.module}/../build/processor.zip"
}

data "archive_file" "upload_api" {
  type        = "zip"
  source_dir  = "${path.module}/../src/upload_api"
  output_path = "${path.module}/../build/upload-api.zip"
}

resource "aws_s3_bucket" "incoming" {
  bucket        = "${local.name}-incoming"
  force_destroy = false
  tags          = local.common_tags
}

resource "aws_s3_bucket" "processed" {
  bucket        = "${local.name}-processed"
  force_destroy = false
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "incoming" {
  bucket                  = aws_s3_bucket.incoming.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  rule {
    id = "expire-pilot-uploads"
    status = "Enabled"
    filter { prefix = "incoming/" }
    expiration { days = 30 }
    noncurrent_version_expiration { noncurrent_days = 7 }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id
  rule {
    id = "expire-pilot-outputs"
    status = "Enabled"
    filter { prefix = "processed/" }
    expiration { days = 30 }
  }
}

resource "aws_s3_bucket_versioning" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name}-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
  tags                      = local.common_tags
}

resource "aws_sqs_queue" "processing" {
  name                       = "${local.name}-processing"
  visibility_timeout_seconds = var.lambda_timeout * 6
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
  tags = local.common_tags
}

data "aws_iam_policy_document" "s3_to_sqs" {
  statement {
    sid     = "AllowIncomingBucketEvents"
    effect  = "Allow"
    actions = ["sqs:SendMessage"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    resources = [aws_sqs_queue.processing.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.incoming.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_sqs_queue_policy" "processing" {
  queue_url = aws_sqs_queue.processing.id
  policy    = data.aws_iam_policy_document.s3_to_sqs.json
}

resource "aws_s3_bucket_notification" "incoming" {
  bucket = aws_s3_bucket.incoming.id
  queue {
    queue_arn     = aws_sqs_queue.processing.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "incoming/"
  }
  depends_on = [aws_sqs_queue_policy.processing]
}

resource "aws_dynamodb_table" "metadata" {
  name         = "${local.name}-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "object_id"
  attribute {
    name = "object_id"
    type = "S"
  }
  server_side_encryption { enabled = true }
  point_in_time_recovery { enabled = false }
  tags = local.common_tags
}

resource "aws_sns_topic" "notifications" {
  name              = "${local.name}-notifications"
  kms_master_key_id = "alias/aws/sns"
  tags              = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_iam_role" "processor" {
  name = "${local.name}-processor-role"
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

resource "aws_iam_role_policy" "processor" {
  name = "${local.name}-processor-policy"
  role = aws_iam_role.processor.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.incoming.arn}/incoming/*"]
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.processed.arn}/processed/*"]
      },
      {
        Effect = "Allow"
        Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
        Resource = [aws_sqs_queue.processing.arn]
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:UpdateItem"]
        Resource = [aws_dynamodb_table.metadata.arn]
      },
      {
        Effect = "Allow"
        Action = ["sns:Publish"]
        Resource = [aws_sns_topic.notifications.arn]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${local.name}-processor:*"]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "processor" {
  name              = "/aws/lambda/${local.name}-processor"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_function" "processor" {
  function_name    = "${local.name}-processor"
  role             = aws_iam_role.processor.arn
  filename         = local.processor_zip
  source_code_hash = filebase64sha256(local.processor_zip)
  handler          = "image_processor.handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  architectures    = ["x86_64"]
  environment {
    variables = {
      OUTPUT_BUCKET = aws_s3_bucket.processed.bucket
      TABLE_NAME    = aws_dynamodb_table.metadata.name
      TOPIC_ARN     = aws_sns_topic.notifications.arn
      MAX_INPUT_BYTES = "10485760"
      MAX_IMAGE_PIXELS = "40000000"
      MAX_DIMENSION = "1600"
      JPEG_QUALITY = "85"
    }
  }
  depends_on = [aws_cloudwatch_log_group.processor, aws_iam_role_policy.processor]
  tags       = local.common_tags
}

resource "aws_lambda_event_source_mapping" "processing" {
  event_source_arn        = aws_sqs_queue.processing.arn
  function_name           = aws_lambda_function.processor.arn
  batch_size              = 5
  function_response_types = ["ReportBatchItemFailures"]
  enabled                 = true
}

resource "aws_iam_role" "upload" {
  name = "${local.name}-upload-role"
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

resource "aws_iam_role_policy" "upload" {
  name = "${local.name}-upload-policy"
  role = aws_iam_role.upload.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.incoming.arn}/incoming/*"]
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${local.name}-upload:*"]
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "upload" {
  name              = "/aws/lambda/${local.name}-upload"
  retention_in_days = 14
  tags              = local.common_tags
}

resource "aws_lambda_function" "upload" {
  function_name    = "${local.name}-upload"
  role             = aws_iam_role.upload.arn
  filename         = data.archive_file.upload_api.output_path
  source_code_hash = data.archive_file.upload_api.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  memory_size      = 256
  environment {
    variables = { UPLOAD_BUCKET = aws_s3_bucket.incoming.bucket }
  }
  depends_on = [aws_cloudwatch_log_group.upload, aws_iam_role_policy.upload]
  tags       = local.common_tags
}

resource "aws_cognito_user_pool" "users" {
  name = "${local.name}-users"
  auto_verified_attributes = ["email"]
  password_policy {
    minimum_length = 12
    require_lowercase = true
    require_numbers = true
    require_symbols = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }
  admin_create_user_config {
    allow_admin_create_user_only = false
  }
  tags = local.common_tags
}

resource "aws_cognito_user_pool_client" "app" {
  name = "${local.name}-app"
  user_pool_id = aws_cognito_user_pool.users.id
  generate_secret = false
  explicit_auth_flows = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"
  access_token_validity = 60
  id_token_validity = 60
  refresh_token_validity = 7
  token_validity_units {
    access_token = "minutes"
    id_token = "minutes"
    refresh_token = "days"
  }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id = aws_apigatewayv2_api.upload.id
  authorizer_type = "JWT"
  name = "cognito-jwt"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = [aws_cognito_user_pool_client.app.id]
    issuer = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.users.id}"
  }
}
resource "aws_apigatewayv2_api" "upload" {
  name          = "${local.name}-upload-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = var.allowed_origins
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
  tags = local.common_tags
}

resource "aws_apigatewayv2_integration" "upload" {
  api_id                 = aws_apigatewayv2_api.upload.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.upload.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "upload" {
  api_id    = aws_apigatewayv2_api.upload.id
  route_key          = "POST /uploads"
  target             = "integrations/${aws_apigatewayv2_integration.upload.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_stage" "upload" {
  api_id      = aws_apigatewayv2_api.upload.id
  name        = "$default"
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowHttpApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.upload.execution_arn}/*/*"
}
