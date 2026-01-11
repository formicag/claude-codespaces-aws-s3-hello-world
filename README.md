# AWS S3 Static Website with DevSecOps Pipeline

A reference implementation for deploying AWS infrastructure using GitHub Actions, Terraform, and OIDC authentication - developed entirely through Claude Code in GitHub Codespaces.

## Overview

This repository demonstrates a complete DevSecOps workflow that can be executed from any device with a browser. The key insight: Claude Code running in Codespaces can authenticate with AWS, deploy infrastructure, verify deployments, and debug issues - enabling seamless transitions between desktop and mobile development.

**Live Site:** http://claude-codespaces-aws-s3-hello-world-site.s3-website-eu-west-1.amazonaws.com

---

## Architecture

```
Developer (any device)
       │
       ▼ git push
GitHub ─────────────────────────────────────────────────────────────────
       │
       ├─► Secret Scanning (pre-receive)
       │
       └─► GitHub Actions Workflow
              │
              ├─► Security Scan (Trivy IaC) ──► GitHub Security Tab
              ├─► Cost Estimation (Infracost) ──► PR Comments
              ├─► Terraform Plan
              └─► Terraform Apply (main only) ──► AWS
                     │
                     ├─► S3 Static Website
                     ├─► IAM Role (OIDC)
                     ├─► DynamoDB (State Lock)
                     └─► CloudWatch (Audit Logs)
```

---

## Key Implementation Details

### OIDC Authentication

GitHub Actions authenticates with AWS using OIDC federation - no stored credentials.

```hcl
# Trust policy on IAM role
Condition = {
  StringEquals = {
    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
  }
  StringLike = {
    "token.actions.githubusercontent.com:sub" = "repo:${org}/${repo}:*"
  }
}
```

**Flow:** GitHub Actions requests a JWT → AWS validates with GitHub's OIDC provider → AWS issues temporary credentials (1hr TTL)

### CI/CD Pipeline

Four-stage pipeline in `.github/workflows/deploy.yml`:

| Stage | Trigger | Purpose |
|-------|---------|---------|
| `security-scan` | All pushes/PRs | Trivy IaC scan, results to Security tab |
| `infracost` | PRs only | Cost delta estimation |
| `terraform-plan` | After security-scan | Preview changes |
| `terraform-apply` | Main branch only | Deploy to AWS |

### Security Tooling

| Tool | Configuration | Output |
|------|---------------|--------|
| **Trivy** | Scans `./terraform` for misconfigurations | SARIF → GitHub Security |
| **Dependabot** | Weekly updates for Terraform + Actions | Auto-PRs |
| **CodeQL** | Enabled in repo settings | GitHub Security |
| **Secret Scanning** | Push protection enabled | Blocks commits with secrets |

### Trivy Findings Analysis

15 findings from initial scan:

| Severity | Count | Notes |
|----------|-------|-------|
| High | 8 | 6 are expected (public website requires public S3 access) |
| Medium | 2 | Versioning + PITR - worth enabling in production |
| Low | 5 | CMK encryption, logging - cost/benefit decision |

Production hardening recommendations:
- Scope IAM from `s3:*` to specific actions
- Enable S3 versioning for rollback
- Enable access logging for audit trails

---

## Repository Structure

```
.
├── .github/
│   ├── workflows/deploy.yml     # CI/CD pipeline
│   └── dependabot.yml           # Dependency updates
├── terraform/
│   ├── bootstrap/               # OIDC, IAM, state backend (run once)
│   └── website/                 # S3, CloudWatch (deployed via Actions)
├── website/                     # Static files
└── AGENTS.md                    # Multi-agent coordination protocol
```

---

## Terraform State Management

- **Backend:** S3 bucket with versioning + encryption
- **Locking:** DynamoDB table
- **Bootstrap:** Run locally once to create state infrastructure

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

---

## Development Workflow

### Local (Mac Terminal)
```bash
aws sso login --profile your-profile
cd terraform/website
terraform plan
```

### Codespaces (Any Device)
Same commands work in Codespaces terminal with Claude Code. AWS CLI authenticates via SSO, Claude can verify deployments by:
- Fetching the live URL
- Reading CloudWatch logs
- Running AWS CLI commands

This enables starting work on desktop, continuing on mobile.

---

## Multi-Agent Collaboration

When multiple Claude Code instances work on the same repo (e.g., Mac terminal + Codespaces), follow the protocol in `AGENTS.md`:

1. Always `git pull` before starting
2. Check `AGENT_STATUS.md` for work in progress
3. Commit frequently, push regularly
4. Use feature branches for larger changes

---

## Security Practices

| Practice | Implementation |
|----------|----------------|
| No stored credentials | OIDC federation |
| IaC scanning | Trivy in CI/CD |
| Dependency updates | Dependabot weekly |
| Secret detection | GitHub push protection |
| Least privilege | Scoped IAM policies |
| State encryption | S3 SSE-AES256 |
| State locking | DynamoDB |
| Audit trail | CloudWatch deployment logs |

---

## Quick Reference

### Useful Commands
```bash
# Verify AWS auth
aws sts get-caller-identity

# Check website
curl -I http://claude-codespaces-aws-s3-hello-world-site.s3-website-eu-west-1.amazonaws.com

# View deployment logs
aws logs filter-log-events --log-group-name "/aws/s3/claude-codespaces-aws-s3-hello-world-site"

# Terraform
terraform fmt -check    # Lint
terraform validate      # Syntax
terraform plan          # Preview
terraform apply         # Deploy
```

### Key Files
| File | Purpose |
|------|---------|
| `.github/workflows/deploy.yml` | CI/CD pipeline definition |
| `terraform/bootstrap/main.tf` | OIDC provider, IAM role, state backend |
| `terraform/website/main.tf` | S3 bucket, website config, CloudWatch |

---

## Notes

- Dependabot PRs may fail Terraform Plan (OIDC doesn't trust Dependabot's context) - safe to merge anyway
- Some Trivy "High" findings are false positives for public static websites
- Infracost requires `INFRACOST_API_KEY` secret for full functionality

---

*Built with Claude Code in GitHub Codespaces*
