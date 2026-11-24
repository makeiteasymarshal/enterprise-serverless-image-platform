# GitHub Actions OIDC trust setup

This repository's workflow only verifies the federated identity. It does not deploy AWS resources.

## 1. Create the IAM OIDC provider

- Provider URL: `https://token.actions.githubusercontent.com`
- Audience: `sts.amazonaws.com`

If this provider already exists in the AWS account, reuse it.

## 2. Create an IAM role trust policy

Replace `ACCOUNT_ID` and use the repository's exact owner/name. Keep the branch restriction; do not use a wildcard repository subject.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:makeiteasymarshal/enterprise-serverless-image-platform:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

## 3. Configure GitHub

Add repository variable `AWS_DEPLOY_ROLE_ARN` containing the role ARN. Do not store static AWS access keys.

## 4. Verify

Run Actions → Manual AWS identity verification → Run workflow and enter `VERIFY`. The job should print the assumed AWS role identity.

Before enabling Terraform deployment, provision an encrypted remote S3 state bucket, state locking, protected GitHub Environment approvals, and a separate least-privilege deployment role. Do not give this identity administrator access.
