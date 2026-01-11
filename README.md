# AWS S3 Static Website with GitHub Actions & OIDC

A production-ready static website deployed to AWS S3, demonstrating modern CI/CD practices with infrastructure as code. **Built entirely using Claude Code in GitHub Codespaces.**

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  GitHub Repo    │────▶│  GitHub Actions  │────▶│    AWS S3       │
│  (Source Code)  │     │  (CI/CD Pipeline)│     │  (Static Site)  │
└─────────────────┘     └────────┬─────────┘     └─────────────────┘
                                 │
                                 │ OIDC Auth
                                 ▼
                        ┌──────────────────┐
                        │    AWS IAM       │
                        │  (No Secrets!)   │
                        └──────────────────┘
```

## Features

- **Infrastructure as Code**: All AWS resources defined in Terraform
- **Secure Authentication**: GitHub Actions uses OIDC to authenticate with AWS (no stored credentials)
- **Automated Deployments**: Push to `main` triggers automatic deployment
- **State Management**: Terraform state stored securely in S3 with DynamoDB locking
- **Monitoring**: CloudWatch integration for deployment logging

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── bootstrap/              # One-time setup (OIDC, IAM, state backend)
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── providers.tf
│   └── website/                # S3 website infrastructure
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── providers.tf
├── website/                    # Static website files
│   ├── index.html
│   ├── error.html
│   └── styles.css
└── README.md
```

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository
- AWS CLI installed and configured
- Terraform >= 1.0

## Setup Instructions

### 1. Bootstrap AWS Infrastructure

First, deploy the bootstrap infrastructure to set up OIDC authentication and Terraform state management:

```bash
cd terraform/bootstrap
terraform init
terraform plan
terraform apply
```

This creates:
- GitHub OIDC Identity Provider in AWS
- IAM Role for GitHub Actions
- S3 bucket for Terraform state
- DynamoDB table for state locking

### 2. Configure GitHub Environment

Create a `production` environment in your GitHub repository:
1. Go to Settings > Environments
2. Create new environment named `production`
3. (Optional) Add protection rules

### 3. Deploy

Push to `main` branch to trigger the deployment pipeline:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

## Security Best Practices

- **No stored secrets**: Uses OIDC federation instead of access keys
- **Least privilege**: IAM role has minimal required permissions
- **State encryption**: Terraform state encrypted at rest in S3
- **State locking**: DynamoDB prevents concurrent modifications

## Technologies Used

| Technology | Purpose |
|------------|---------|
| AWS S3 | Static website hosting |
| Terraform | Infrastructure as Code |
| GitHub Actions | CI/CD automation |
| OIDC | Secure AWS authentication |
| CloudWatch | Monitoring and logging |
| Claude Code | AI-powered development |

## How This Was Built

This entire project was created using **Claude Code** in GitHub Codespaces through natural language conversation:

1. Described the desired architecture
2. Claude Code generated all Terraform configurations
3. Created the static website with responsive design
4. Set up GitHub Actions workflow with OIDC authentication
5. Deployed infrastructure and verified the deployment

## License

MIT License - feel free to use this as a template for your own projects.
