# Enterprise AWS Platform Architecture

## Workloads
1. Existing serverless image pipeline: authenticated upload API -> private S3 incoming bucket -> SQS + DLQ -> image processor Lambda -> processed S3 prefix/bucket -> DynamoDB status -> optional SNS/SES notification.
2. Enterprise application workload (future phase): Route 53/ACM -> ALB -> ECS Fargate or EKS services -> private RDS; use this only when a container workload is required.
3. Shared foundation: isolated accounts (management, security/log archive, non-production, production), VPC segmentation, IAM federation, centralized audit, CI/CD, observability, backup and recovery.

## Request flow
Client -> Cognito-authenticated API Gateway -> upload Lambda -> presigned S3 PUT -> S3 event -> SQS -> processor Lambda -> processed S3 + DynamoDB -> notification.

## Network design
- Two Availability Zones.
- Public subnets reserved for internet-facing ingress such as ALB.
- Private application subnets for compute.
- No public IPs on private workloads.
- NAT Gateway intentionally not provisioned by default; choose NAT per AZ or VPC endpoints after cost and egress review.
- Security groups are stateful and should allow only required source security groups and ports.

## Account strategy
Production-grade target: AWS Organizations with separate management, security/log archive, non-production, and production accounts. The current personal-account lab deploys only the isolated VPC foundation. Do not represent a single-account lab as a deployed multi-account landing zone.

## Reliability and delivery
- SQS buffering and DLQ for asynchronous workload resilience.
- Lambda idempotency and bounded retries are required for duplicate event delivery.
- CI uses GitHub Actions; AWS access should use OIDC with a narrowly scoped role trust policy.
- Production deployments require protected environments, approvals, remote Terraform state with locking, rollback procedures, and tested restore runbooks.
