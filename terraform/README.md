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

The stack creates two S3 buckets, SQS + DLQ, three Lambda functions (upload, processor, status), Cognito User Pool, JWT-protected API Gateway routes, DynamoDB, SNS, IAM roles, CloudWatch log groups and alarms. These resources may incur charges. The deployment is single-region and is intended for a controlled pilot only.

## Pilot test
Get the API URL:

```powershell
terraform -chdir=terraform output -raw upload_api_url
```

Create a Cognito user and confirm the email verification code. Then authenticate and use the returned ID token:

```powershell
$pool = terraform -chdir=terraform output -raw cognito_user_pool_id
$client = terraform -chdir=terraform output -raw cognito_app_client_id
aws cognito-idp sign-up --client-id $client --username "you@example.com" --password "Use-A-Strong-Unique-Password-123!"
# Read the email verification code, then:
aws cognito-idp confirm-sign-up --client-id $client --username "you@example.com" --confirmation-code "EMAIL_CODE"
$auth = aws cognito-idp initiate-auth --client-id $client --auth-flow USER_PASSWORD_AUTH --auth-parameters USERNAME="you@example.com",PASSWORD="Use-A-Strong-Unique-Password-123!" | ConvertFrom-Json
$token = $auth.AuthenticationResult.IdToken
```

Request a presigned URL:

```powershell
$api = terraform -chdir=terraform output -raw upload_api_url
$payload = @{ filename = "sample.png"; content_type = "image/png" } | ConvertTo-Json
$headers = @{ Authorization = "Bearer $token" }
$result = Invoke-RestMethod -Method Post -Uri "$api/uploads" -Headers $headers -ContentType "application/json" -Body $payload
Invoke-WebRequest -Method Put -Uri $result.upload_url -InFile ".\sample.png" -ContentType "image/png"
```

Check the authenticated status route with `GET $api/status?key=<object_key>` using the same Bearer token. Verify the processed object in the output bucket and inspect Lambda logs / DynamoDB record in the AWS Console.

## Destroy
Run `..\\scripts\\cleanup.ps1` from the repository root to empty the versioned incoming bucket (including versions/delete markers) and the processed bucket. Then:

```powershell
terraform -chdir=terraform plan -destroy
terraform -chdir=terraform destroy
```

Confirm removal in the AWS Console and Billing/Cost Explorer. This project intentionally does not automatically destroy resources.
