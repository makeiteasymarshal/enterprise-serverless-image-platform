# Security controls

- No secrets or AWS credentials are committed.
- GitHub Actions must use OIDC with repository and branch-scoped trust.
- Keep S3 Block Public Access enabled; never make upload buckets public.
- Lambda roles are separated by function and scoped to exact bucket, queue, table and topic ARNs.
- Validate content type and actual decoded image format; impose byte and pixel limits.
- Use short-lived presigned URLs and short expiration.
- Use TLS for service endpoints and encryption at rest.
- Restrict API request size, rate and authenticated tenant scope.
- Review dependency versions, scan source and artifacts, and pin production dependencies.
- Enable CloudTrail and retain logs according to an approved policy.

## Before production
This starter is not a substitute for a threat model or penetration test. Review IAM, API authorization, input validation, tenant isolation, data retention, encryption, logging of sensitive data, incident response, and recovery objectives.
