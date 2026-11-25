# Implementation Roadmap and Acceptance Criteria

## Phase 1 - Network foundation (this branch)
- [ ] Terraform module creates a two-AZ VPC, public/private subnets, IGW, public route table, and private route tables without NAT.
- [ ] Terraform fmt and validate pass.
- [ ] Plan reviewed before apply; deployed resources tagged and documented.

## Phase 2 - Identity and governance
- [ ] OIDC role for GitHub Actions restricted to this repository and branch/environment.
- [ ] CloudTrail organization trail and AWS Config strategy documented; deploy only after account-level review.
- [ ] Least-privilege workload roles and permission boundaries.

## Phase 3 - Serverless workload hardening
- [ ] S3 event -> SQS -> Lambda, DLQ alarms, encryption, lifecycle and public access block.
- [ ] Idempotency / duplicate notification suppression.
- [ ] File signature and size validation, malware scanning decision, tenant authorization.
- [ ] DynamoDB point-in-time recovery and backup/restore test.

## Phase 4 - Container workload
- [ ] Build and scan Docker image, push to ECR, deploy to ECS Fargate (EKS is an optional advanced extension).
- [ ] ALB health checks, private service networking, secrets from Secrets Manager.

## Phase 5 - Observability, security and resilience
- [ ] CloudWatch dashboards, alarms, structured logs and actionable notifications.
- [ ] Security Hub, GuardDuty, Inspector and WAF evaluated against actual need and cost.
- [ ] Backup restore test, documented RTO/RPO, DR exercise and cost review.

## Definition of done
A phase is complete only when code is reviewed, Terraform validation passes, a deployment is actually tested, evidence is recorded, and cleanup or ongoing cost ownership is explicit. A diagram or planned module is not proof of deployment.
