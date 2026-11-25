# Enterprise Cloud Upgrade

This directory extends the existing serverless image platform with a reusable cloud foundation. It is intentionally additive: the original application and Terraform pilot remain unchanged.

## Scope in this branch
- Reusable, two-AZ VPC network module with public and private application subnets.
- Development environment root module (Mumbai by default).
- Architecture, security, operations, and phased expansion documentation.
- Terraform CI validation. No automatic AWS apply is enabled.

## Important
The network module creates billable or quota-consuming AWS resources only when you run Terraform locally. NAT Gateway is deliberately excluded from the baseline to avoid an unexpected hourly charge. Private subnets have no outbound internet route until you explicitly add NAT or VPC endpoints.

## Local validation (PowerShell)
```powershell
cd C:\AWS-Labs\enterprise-serverless-image-platform\platform\terraform\environments\dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform show tfplan
```

Review the complete plan and AWS pricing before `terraform apply`. Do not commit state files, plan files, credentials, or tfvars containing secrets.
