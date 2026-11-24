# Project plan and acceptance criteria

## Pilot scope
- [ ] Validate JPEG, PNG and WebP input; reject malformed/unsupported data.
- [ ] Keep upload and processed objects private.
- [ ] Process S3 events asynchronously through SQS.
- [ ] Retry transient failures and route exhausted messages to a DLQ.
- [ ] Persist deterministic processing status and output object location.
- [ ] Emit optional SNS completion/failure notifications.
- [ ] Test locally before any AWS deployment.
- [ ] Capture architecture, test output, deployment evidence and cleanup evidence.

## Production backlog
1. Add file-signature inspection and malware scanning.
2. Add tenant-aware authorization and per-tenant object prefixes.
3. Add object size enforcement at upload boundary and API throttling/WAF.
4. Add robust idempotency state machine with lease expiry and conditional transitions.
5. Add structured metrics, tracing, dashboards, alarms and runbooks.
6. Define SLO, RTO, RPO, retention, backup and regional failover.
7. Run load, chaos, dependency and security testing.
8. Review data residency, encryption key policy and audit requirements.
