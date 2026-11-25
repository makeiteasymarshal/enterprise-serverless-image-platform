# Security and Cost Guardrails

- Never commit AWS access keys, GitHub tokens, private keys, state files, plan files, or secret tfvars.
- Use GitHub OIDC and a dedicated IAM role; restrict trust to the exact repository and branch/environment.
- Use least-privilege permissions. Do not use AdministratorAccess for routine deployment.
- Keep S3 Block Public Access enabled; encrypt data at rest and use TLS in transit.
- Keep compute in private subnets. Do not add SSH ingress from 0.0.0.0/0.
- Enable CloudTrail and suitable audit retention after reviewing account-level scope and charges.
- Review Terraform plan, region, resource count, and pricing before apply.
- NAT Gateway, ALB, RDS, ECS Fargate, EKS, GuardDuty, Security Hub, Config, CloudTrail data events, and log ingestion can incur charges.
- Configure AWS Budgets and billing alerts before creating billable resources.
- Destroy lab resources after testing. Empty versioned S3 buckets and verify dependent resources before destroy.
