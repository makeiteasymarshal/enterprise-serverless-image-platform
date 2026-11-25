# Test Plan

## Static checks
1. terraform fmt -check -recursive
2. terraform init -backend=false
3. terraform validate
4. Review terraform plan for unexpected public ingress, NAT, databases, or paid services.

## Network acceptance after approved deployment
1. Confirm VPC CIDR and two AZs.
2. Confirm public subnets have a default route to the Internet Gateway.
3. Confirm private subnets have no default internet route in the baseline.
4. Confirm private subnet resources do not receive public IPs.
5. Confirm route tables are associated with the intended subnets.
6. Confirm tags identify project, environment, and owner.

## Existing serverless workload acceptance
1. Obtain an authenticated upload URL.
2. Upload a valid image.
3. Confirm S3 object-created event is queued.
4. Confirm Lambda processes the message.
5. Confirm processed image and DynamoDB status.
6. Confirm notification delivery when configured.
7. Submit an invalid file and verify safe rejection.
8. Force a controlled processor failure and verify retry/DLQ behavior.
9. Replay an event and verify idempotency behavior before production claims.
10. Verify unauthorized API and S3 access are denied.

## Evidence
Save sanitized command output, CloudWatch log excerpts, GitHub Actions run URLs, screenshots, and test timestamps under docs/evidence. Never include credentials or customer data.
