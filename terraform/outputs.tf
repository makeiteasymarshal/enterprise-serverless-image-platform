output "upload_api_url" {
  description = "Base URL for the upload API"
  value       = aws_apigatewayv2_api.upload.api_endpoint
}

output "incoming_bucket_name" {
  value = aws_s3_bucket.incoming.bucket
}

output "processed_bucket_name" {
  value = aws_s3_bucket.processed.bucket
}

output "metadata_table_name" {
  value = aws_dynamodb_table.metadata.name
}

output "processing_queue_url" {
  value = aws_sqs_queue.processing.url
}

output "dead_letter_queue_url" {
  value = aws_sqs_queue.dlq.url
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.users.id
}

output "cognito_app_client_id" {
  value = aws_cognito_user_pool_client.app.id
}
