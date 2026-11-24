# Source repository integration map

This project consolidates reusable ideas and selected patterns from the user's existing repositories. It does not blindly copy upstream source trees or preserve unsafe legacy snippets.

| Source repository | Reused concept | New implementation |
|---|---|---|
| Terraform | AWS infrastructure, Lambda, S3, DynamoDB, SNS, custom resource and cost-governance patterns | A new single-region Terraform stack with isolated IAM roles, encrypted S3, SQS/DLQ, Cognito, API Gateway, DynamoDB and CloudWatch alarms |
| Successful-Codes | S3-triggered Python automation, image watermarking, API authorizer and metadata integration | New upload, processing and status Lambda handlers with input validation and Cognito JWT protection |
| Pillow | Python Imaging Library image manipulation | Pillow is installed as a pinned dependency and used for safe image decoding, EXIF orientation, resize, watermark and JPEG optimization |
| Klayers | Lambda dependency packaging, layer build automation, GitHub OIDC concepts | Linux-compatible Lambda ZIP build via Docker and a repository-scoped OIDC identity-check workflow |
| makeiteasymarshal | Portfolio and documentation destination | This repository is the consolidated project portfolio |

## Deliberate exclusions

- Do not copy upstream Pillow source code into this application; use the maintained package dependency.
- Do not reuse the old Klayers Terraform remote backend or its organization-specific state settings.
- Do not carry over hardcoded authorizer tokens, account IDs, bucket names, broad IAM policies, or invalid CloudFormation custom-resource response code.
- CUDOS and Trusted Advisor dashboard notes are operational governance references, not application runtime dependencies.
- The first implementation is a single-region pilot. Multi-region replication, DR orchestration, enterprise tenant isolation, malware scanning, and automated Terraform apply remain future production-hardening work.
