# Terraform pilot deployment

## Prerequisites
- Terraform 1.6+
- AWS CLI v2 authenticated to a dedicated lab account/profile
- Python 3.11 and PowerShell
- Review the AWS pricing page and set an AWS Budget before deployment

## Build and deploy
From the repository root:

```powershell
.\scripts\build.ps1
$env:AWS_PROFILE = "your-lab-profile"
terraform -chdir=terraform init
terraform -chdir=terraform fmt -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=tfplan
terraform -chdir=terraform apply tfplan
```

The stack creates two S3 buckets, SQS + DLQ, Lambda functions, DynamoDB, SNS, API Gateway HTTP API, IAM roles and CloudWatch log groups. These resources may incur charges. The deployment is single-region and is intended for a controlled pilot only.

## Pilot test
Get the API URL:

```powershell
terraform -chdir=terraform output -raw upload_api_url
```

Request a presigned URL:

```powershell
$api = terraform -chdir=terraform output -raw upload_api_url
$payload = @{ filename = "sample.png"; content_type = "image/png" } | ConvertTo-Json
$result = Invoke-RestMethod -Method Post -Uri "$api/uploads" -ContentType "application/json" -Body $payload
Invoke-WebRequest -Method Put -Uri $result.upload_url -InFile ".\sample.png" -ContentType "image/png"
```

Verify the processed object in the output bucket and inspect Lambda logs / DynamoDB record in the AWS Console.

## Destroy
First empty both buckets. If versioning is enabled, delete all object versions and delete markers. Then:

```powershell
terraform -chdir=terraform plan -destroy
terraform -chdir=terraform destroy
```

Confirm removal in the AWS Console and Billing/Cost Explorer. This project intentionally does not automatically destroy resources.
