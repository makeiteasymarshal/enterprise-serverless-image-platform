# Enterprise Serverless Image Processing Platform

A portfolio-grade AWS serverless reference implementation combining secure image intake, asynchronous processing, metadata tracking, notifications, Infrastructure as Code, and GitHub Actions CI.

> **Status:** Pilot-ready starter. The Python application and automated tests are designed for local validation. AWS deployment is opt-in and has not been run against an AWS account. Review costs, permissions, quotas, and regional availability before deployment.

## Architecture

```text
Client
  | (presigned PUT URL from Upload API)
  v
API Gateway -> Upload Lambda -> S3 incoming/
                                  |
                                  v
                              SQS queue -> DLQ
                                  |
                                  v
                         Image Processor Lambda
                           |       |        |
                           v       v        v
                      S3 processed/ DynamoDB SNS
```

S3 notifications enqueue object-created events. SQS buffers bursts and isolates failures. The processor validates the image, applies resize/compression/optional watermarking with Pillow, writes the result to a separate bucket prefix, and records processing status in DynamoDB. An optional SNS topic sends completion/failure notifications.

## Repository layout

- `src/image_processor/`: SQS-triggered Lambda handler and image processing logic.
- `src/upload_api/`: API Lambda that returns short-lived S3 presigned upload URLs.
- `tests/`: unit tests using pytest and moto.
- `terraform/`: single-region AWS infrastructure, least-privilege IAM, queue/DLQ, buckets, table, topic and Lambda wiring.
- `.github/workflows/`: Python CI and Terraform validation.
- `scripts/`: local packaging and pilot-test helpers.

## Design and safety notes

- The incoming and processed S3 buckets are private with public access blocked and default encryption enabled.
- S3 sends events to SQS; Lambda consumes SQS messages. A DLQ captures repeatedly failing messages.
- The processor is idempotent at the object-version level using a DynamoDB conditional write. Duplicate delivery is expected in distributed event systems.
- Upload API validates filename extension and content type, but production systems must also enforce file-size limits, inspect actual file signatures, malware-scan where appropriate, and apply tenant authorization.
- The example uses SSE-S3 to avoid requiring customer-managed KMS key administration in a pilot. Adopt SSE-KMS and key policies when required.
- GitHub Actions uses OIDC only when configured; no long-lived AWS keys are stored.
- Terraform creates billable AWS resources. **Do not run `terraform apply` until you have reviewed the plan and AWS pricing.** Always destroy pilot resources and empty S3 buckets first.
- This is an engineering portfolio project, not a certified production service. Production rollout requires threat modelling, load tests, operational ownership, data retention decisions, alert routing, DR objectives, and security review.

## Local development

Requirements: Python 3.11+, Git. Docker is optional.

```powershell
git clone https://github.com/makeiteasymarshal/enterprise-serverless-image-platform.git
cd enterprise-serverless-image-platform
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements-dev.txt
pytest -q
ruff check .
```

## Pilot AWS deployment (optional)

1. Configure AWS CLI with a dedicated least-privilege lab profile.
2. Review `terraform/README.md` and `terraform/variables.tf`.
3. Build the Lambda package with `scripts/build.ps1`.
4. Run `terraform init`, `terraform fmt -check -recursive`, `terraform validate`, and `terraform plan`.
5. Inspect every resource and estimated cost. Only then consider `terraform apply`.
6. Upload a test image using the presigned URL returned by the upload Lambda/API.
7. Verify the processed object, DynamoDB record, CloudWatch logs, and optional SNS message.
8. Follow the cleanup instructions in `terraform/README.md`.

## GitHub Actions OIDC setup

The workflow in `.github/workflows/deploy.yml` is intentionally manual and gated. Create an AWS IAM OIDC provider for `token.actions.githubusercontent.com`, then create a role whose trust policy restricts the subject to this repository and the protected `main` branch. Add the role ARN as repository variable `AWS_DEPLOY_ROLE_ARN`. The role needs only the actions required by the deployment workflow and Terraform resources. Do not add static AWS access keys.

## Project milestones

1. Local tests and code quality.
2. Pilot single-region deployment.
3. Security hardening and load testing.
4. Multi-region disaster-recovery design and controlled implementation.
5. Dashboards, SLOs, runbooks, and interview demo.

See `docs/PROJECT_PLAN.md`, `docs/SECURITY.md`, and `docs/OPERATIONS.md`.
