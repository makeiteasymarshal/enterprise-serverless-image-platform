# Operations and troubleshooting

## Signals
- Lambda Errors, Duration, Throttles and ConcurrentExecutions.
- SQS ApproximateAgeOfOldestMessage and ApproximateNumberOfMessagesVisible.
- DLQ visible message count.
- DynamoDB throttling and system errors.
- S3 4xx/5xx request metrics where enabled.

## Runbook
1. Inspect the SQS DLQ and CloudWatch log stream for the failed message ID.
2. Confirm source object exists and is within configured byte/pixel limits.
3. Confirm Lambda role can read incoming objects, write processed objects, update the table and publish to SNS.
4. Check Lambda timeout, memory and SQS visibility timeout alignment.
5. Redrive messages only after correcting the underlying cause.
6. Never delete source data to silence an alarm.

## Cleanup
Run `terraform destroy` only after reviewing the destroy plan. Empty both buckets, including all object versions if versioning has been enabled. Confirm Lambda, API Gateway, SQS, DynamoDB, SNS, CloudWatch log groups and IAM resources have been removed. Check AWS Billing/Cost Explorer afterwards.
