# Mobile-First Cloud Development: A Proof of Concept

> **Deploying production infrastructure from anywhere using AI-powered development in GitHub Codespaces**

## The Vision

This repository demonstrates a paradigm shift in cloud development: the ability to build, deploy, and manage production AWS infrastructure from any device with a browser - including a mobile phone.

---

## Table of Contents

1. [What This POC Proves](#what-this-poc-proves)
2. [The Complete Pattern Explained](#the-complete-pattern-explained)
3. [Deep Dive: GitHub Actions](#deep-dive-github-actions)
4. [Deep Dive: The OIDC Authentication](#deep-dive-the-oidc-authentication)
5. [Deep Dive: Terraform](#deep-dive-terraform)
6. [Deep Dive: Linting and Quality Gates](#deep-dive-linting-and-quality-gates)
7. [The Mobile Development Experience](#the-mobile-development-experience)
8. [Verification Results](#verification-results)
9. [How to Recreate This](#how-to-recreate-this)
10. [Repository Structure](#repository-structure)

---

## What This POC Proves

This proof of concept validates that **a complete production deployment workflow can be executed entirely through natural language conversation with an AI assistant**, from any device, anywhere in the world.

### Key Capabilities Demonstrated

| Capability | Description |
|------------|-------------|
| **Device Agnostic** | Entire workflow executed via browser - works on iPhone, Android, tablet, or desktop |
| **Real-Time Sync** | Commands typed on mobile appeared instantly on desktop and vice versa |
| **Full AWS Integration** | Claude Code authenticated with AWS via SSO and executed real infrastructure changes |
| **End-to-End Deployment** | From empty repo to live website with CI/CD pipeline in a single conversation |
| **Direct Verification** | AI agent accessed the deployed website and CloudWatch logs to confirm success |
| **Complete Teardown** | All AWS resources created and destroyed with verification - zero residual costs |

---

## The Complete Pattern Explained

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MOBILE OR DESKTOP BROWSER                         │
│                                                                          │
│  ┌─────────────────┐    ┌──────────────────┐    ┌───────────────────┐  │
│  │ GitHub Codespace │───▶│   Claude Code    │───▶│   AWS CLI/SSO     │  │
│  │  (VS Code Web)   │    │  (AI Assistant)  │    │  (Direct Access)  │  │
│  └─────────────────┘    └──────────────────┘    └───────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS CLOUD                                   │
│                                                                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐│
│  │  S3 Static  │  │  IAM OIDC   │  │  DynamoDB   │  │   CloudWatch    ││
│  │   Website   │  │    Role     │  │  TF State   │  │     Logs        ││
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────────┘│
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           GITHUB ACTIONS                                 │
│                                                                          │
│  Push to main ──▶ OIDC Auth ──▶ Terraform Plan ──▶ Terraform Apply      │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Breakdown

```
1. You write code (Terraform files, HTML, etc.)
              ↓
2. You commit + push to GitHub
              ↓
3. GitHub detects the push (the "hook")
              ↓
4. GitHub Actions workflow is triggered automatically
              ↓
5. A fresh Linux machine spins up in GitHub's cloud
              ↓
6. Terraform is installed on that machine
              ↓
7. OIDC authenticates with AWS (no passwords stored!)
              ↓
8. Terraform reads your .tf files
              ↓
9. Terraform sends AWS SDK commands directly to AWS APIs
              ↓
10. AWS creates/updates/deletes resources
              ↓
11. Success or failure is reported back
              ↓
12. You see green ✅ or red ❌ in GitHub
```

---

## Deep Dive: GitHub Actions

### What is GitHub Actions?

GitHub Actions is an automation system built into GitHub. It runs code automatically when certain events happen (like pushing code).

### How Does GitHub Know to Run Something?

**There's no manual setup required.** GitHub automatically watches for a special folder structure:

```
your-repo/
├── .github/
│   └── workflows/
│       └── any-name.yml   ← GitHub runs ANY .yml file in here
```

If GitHub sees a `.yml` file in `.github/workflows/`, it reads it and follows the instructions.

### Our Workflow File Explained

The file `.github/workflows/deploy.yml` contains everything:

```yaml
# ═══════════════════════════════════════════════════════════════════════
# PART 1: THE TRIGGER (Hook)
# ═══════════════════════════════════════════════════════════════════════
# This section defines WHEN the workflow runs

name: Deploy S3 Static Website

on:
  push:
    branches:
      - main              # Run when someone pushes to main branch
  pull_request:
    branches:
      - main              # Run when someone opens a PR to main
  workflow_dispatch:       # Allow manual trigger from GitHub UI

# Other triggers you could use:
#   schedule:
#     - cron: '0 9 * * *'  # Run every day at 9am
#   release:
#     types: [published]   # Run when a release is published


# ═══════════════════════════════════════════════════════════════════════
# PART 2: PERMISSIONS
# ═══════════════════════════════════════════════════════════════════════
# What is this workflow allowed to do?

permissions:
  id-token: write    # Required for OIDC authentication with AWS
  contents: read     # Can read the repository code


# ═══════════════════════════════════════════════════════════════════════
# PART 3: ENVIRONMENT VARIABLES
# ═══════════════════════════════════════════════════════════════════════
# Shared configuration values

env:
  AWS_REGION: eu-west-1
  TF_VERSION: 1.6.0


# ═══════════════════════════════════════════════════════════════════════
# PART 4: THE JOBS
# ═══════════════════════════════════════════════════════════════════════
# The actual work to be done

jobs:
  # -------------------------------------------------------------------
  # JOB 1: Plan (runs on every push and PR)
  # -------------------------------------------------------------------
  terraform-plan:
    name: Terraform Plan
    runs-on: ubuntu-latest    # Use a fresh Linux machine

    steps:
      # STEP A: Download the code onto the machine
      - name: Checkout code
        uses: actions/checkout@v4
        # This downloads your repo to the GitHub runner

      # STEP B: Authenticate with AWS using OIDC
      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::016164185850:role/github-actions-xxx
          aws-region: ${{ env.AWS_REGION }}
        # No passwords! OIDC handles authentication securely

      # STEP C: Install Terraform
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}

      # STEP D: Initialize Terraform
      - name: Terraform Init
        working-directory: terraform/website
        run: terraform init
        # Downloads providers, sets up backend

      # STEP E: Check code formatting (LINTING!)
      - name: Terraform Format Check
        working-directory: terraform/website
        run: terraform fmt -check
        # Fails if code isn't properly formatted

      # STEP F: Validate configuration
      - name: Terraform Validate
        working-directory: terraform/website
        run: terraform validate
        # Checks for syntax errors

      # STEP G: Create the plan
      - name: Terraform Plan
        working-directory: terraform/website
        run: terraform plan -out=tfplan
        # Shows what WILL change (doesn't change anything yet)


  # -------------------------------------------------------------------
  # JOB 2: Apply (only runs on push to main, after plan succeeds)
  # -------------------------------------------------------------------
  terraform-apply:
    name: Terraform Apply
    runs-on: ubuntu-latest
    needs: terraform-plan              # Must wait for plan job
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production            # Can add manual approval here

    steps:
      # ... similar steps, but ends with:
      - name: Terraform Apply
        run: terraform apply -auto-approve tfplan
        # Actually makes the changes in AWS
```

### The "Hook" Trigger Explained

```yaml
on:
  push:
    branches:
      - main
```

**What this means in plain English:**

"Hey GitHub, whenever ANYONE pushes commits to the `main` branch, please run this workflow."

**The sequence:**

```
Developer: git push origin main
                ↓
GitHub: "I received a push to main branch"
                ↓
GitHub: "Let me check .github/workflows/ folder"
                ↓
GitHub: "Found deploy.yml!"
                ↓
GitHub: "Reading the 'on:' section... it says 'push to main'"
                ↓
GitHub: "That matches! Starting the workflow..."
                ↓
Workflow runs automatically
```

### The Machine (Runner)

```yaml
runs-on: ubuntu-latest
```

**What this means:**

GitHub spins up a fresh Linux virtual machine in their cloud. This machine:
- Has nothing installed except basic Linux tools
- Exists for ~5-10 minutes while your workflow runs
- Gets completely deleted afterward
- Is free (up to 2,000 minutes/month)

**Think of it like:** Renting a computer for 5 minutes, using it, then returning it.

### Steps Explained

Each step is one command or action:

```yaml
steps:
  # Using a pre-built action (someone else wrote this)
  - name: Checkout code
    uses: actions/checkout@v4

  # Running a raw shell command
  - name: Terraform Plan
    run: terraform plan

  # Running multiple commands
  - name: Build and Test
    run: |
      npm install
      npm run build
      npm test
```

---

## Deep Dive: The OIDC Authentication

### The Problem OIDC Solves

**Old way (bad):**
```yaml
# DON'T DO THIS - storing secrets in GitHub
env:
  AWS_ACCESS_KEY_ID: AKIA1234567890
  AWS_SECRET_ACCESS_KEY: abcdef123456  # Anyone who hacks GitHub gets your AWS!
```

**New way (OIDC):**
```yaml
# No secrets stored anywhere!
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456:role/my-role
```

### How OIDC Works (Hotel Analogy)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ TRADITIONAL WAY (Like carrying cash)                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  GitHub stores AWS password ──▶ Sends password to AWS ──▶ AWS lets in   │
│                                                                          │
│  Problem: If someone steals the password, they have permanent access    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ OIDC WAY (Like a company badge)                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  1. GitHub: "Hi AWS, I'm GitHub Actions running for repo X"             │
│                          ↓                                               │
│  2. AWS: "Let me verify with GitHub that you're legit..."               │
│                          ↓                                               │
│  3. GitHub: "Yes, this is really a workflow from repo X"                │
│                          ↓                                               │
│  4. AWS: "OK, here's a TEMPORARY pass (expires in 1 hour)"              │
│                          ↓                                               │
│  5. GitHub Actions uses the temporary pass                               │
│                          ↓                                               │
│  6. Pass expires automatically                                           │
│                                                                          │
│  Benefit: No permanent credentials. Nothing to steal.                   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### What We Set Up in AWS

1. **OIDC Identity Provider** - Tells AWS "trust tokens from GitHub"
2. **IAM Role** - Defines what GitHub Actions can do
3. **Trust Policy** - "Only trust workflows from THIS specific repo"

```
AWS Account
    │
    ├── OIDC Provider (token.actions.githubusercontent.com)
    │       "I trust GitHub"
    │
    └── IAM Role (github-actions-my-repo)
            │
            ├── Trust Policy: "Only repo:myuser/myrepo can assume this role"
            │
            └── Permissions Policy: "Can manage S3, CloudWatch, DynamoDB"
```

---

## Deep Dive: Terraform

### What is Terraform?

Terraform is "Infrastructure as Code" - you write text files describing what you want, and Terraform creates it in AWS.

### Terraform vs AWS CLI

| AWS CLI | Terraform |
|---------|-----------|
| Imperative: "Create a bucket NOW" | Declarative: "A bucket should exist" |
| Doesn't remember what it did | Tracks everything in state file |
| You figure out the order | Figures out dependencies automatically |
| Hard to undo | `terraform destroy` removes everything |
| Step-by-step commands | Describe end result |

### Example Comparison

**AWS CLI approach:**
```bash
# You have to figure out the order and run each command
aws s3api create-bucket --bucket my-site
aws s3api put-bucket-website --bucket my-site --website-configuration ...
aws s3api put-bucket-policy --bucket my-site --policy ...
aws s3 cp index.html s3://my-site/
# And you have to remember all of this to delete it later!
```

**Terraform approach:**
```hcl
# Just describe what you want
resource "aws_s3_bucket" "website" {
  bucket = "my-site"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id
  index_document { suffix = "index.html" }
}

# Terraform figures out the order and tracks everything
# To delete: terraform destroy (removes everything automatically)
```

### How Terraform Talks to AWS

```
Terraform does NOT use AWS CLI!

┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Your .tf   │         │  Terraform  │         │   AWS API   │
│   files     │────────▶│   Engine    │────────▶│  (Direct)   │
└─────────────┘         └─────────────┘         └─────────────┘
                              │
                              │ Uses AWS SDK (code library)
                              │ NOT aws CLI commands
                              ▼
                        Makes HTTPS calls:
                        POST https://s3.amazonaws.com/...
                        POST https://iam.amazonaws.com/...
```

### The Terraform Workflow

```
terraform init      # Download providers, setup backend
       ↓
terraform fmt       # Format code nicely (linting)
       ↓
terraform validate  # Check for syntax errors
       ↓
terraform plan      # Preview: "Here's what I WILL do"
       ↓
terraform apply     # Actually do it
       ↓
(later)
terraform destroy   # Remove everything
```

### Terraform State

Terraform keeps track of what it created in a "state file":

```
┌─────────────────────────────────────────────────────────────────┐
│ terraform.tfstate                                                │
├─────────────────────────────────────────────────────────────────┤
│ {                                                                │
│   "resources": [                                                 │
│     {                                                            │
│       "type": "aws_s3_bucket",                                  │
│       "name": "website",                                         │
│       "id": "claude-codespaces-aws-s3-hello-world-site"         │
│     },                                                           │
│     {                                                            │
│       "type": "aws_cloudwatch_log_group",                       │
│       "name": "website",                                         │
│       "id": "/aws/s3/claude-codespaces-..."                     │
│     }                                                            │
│   ]                                                              │
│ }                                                                │
└─────────────────────────────────────────────────────────────────┘
```

This is how Terraform knows:
- What exists
- What to update
- What to delete

**We stored our state in S3** (not locally) so GitHub Actions could access it.

---

## Deep Dive: Linting and Quality Gates

### What is Linting?

Linting is automated code checking - a robot reads your code and catches problems before they cause issues.

| Type | What it catches | Example |
|------|-----------------|---------|
| **Syntax errors** | Code that won't run | Missing brackets, typos |
| **Style issues** | Inconsistent formatting | Wrong indentation, mixed quotes |
| **Security issues** | Vulnerabilities | Hardcoded passwords |
| **Best practices** | Inefficient code | Unused variables |

### Where Linting Fits in the Pipeline

```
Push to main
       ↓
┌─────────────────────────────────┐
│  LINT (Quality Gate #1)         │  ← Fast, cheap - fail early!
│  - Code formatting              │
│  - Syntax errors                │
│  - Security scanning            │
└─────────────────────────────────┘
       ↓ Only if passes
┌─────────────────────────────────┐
│  TEST (Quality Gate #2)         │
│  - Unit tests                   │
│  - Integration tests            │
└─────────────────────────────────┘
       ↓ Only if passes
┌─────────────────────────────────┐
│  BUILD (Quality Gate #3)        │
│  - Compile code                 │
│  - Create artifacts             │
└─────────────────────────────────┘
       ↓ Only if passes
┌─────────────────────────────────┐
│  DEPLOY (Final Step)            │
│  - Push to production           │
└─────────────────────────────────┘

If ANY gate fails → Pipeline STOPS → Bad code never reaches production
```

### Our Linting Steps

In our workflow, we had these linting/validation steps:

```yaml
# Linting Step 1: Check Terraform formatting
- name: Terraform Format Check
  run: terraform fmt -check
  # Fails if code isn't properly formatted
  # Example: wrong indentation, inconsistent spacing

# Linting Step 2: Validate Terraform syntax
- name: Terraform Validate
  run: terraform validate
  # Fails if there are syntax errors
  # Example: missing required field, wrong resource type
```

### Adding More Linting (Examples)

For a more complete pipeline, you could add:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      # Terraform linting
      - name: Terraform Format
        run: terraform fmt -check

      - name: Terraform Validate
        run: terraform validate

      - name: TFLint (Terraform best practices)
        uses: terraform-linters/setup-tflint@v3
        run: tflint

      # Security scanning
      - name: tfsec (Terraform security)
        uses: aquasecurity/tfsec-action@v1

      # If you had JavaScript:
      - name: ESLint
        run: npx eslint src/*.js

      # If you had Python:
      - name: Pylint
        run: pylint **/*.py

      # If you had HTML:
      - name: HTMLHint
        run: npx htmlhint website/*.html

      # If you had CSS:
      - name: Stylelint
        run: npx stylelint website/*.css
```

### Why Lint First?

```
Without linting:
  Developer pushes broken code
       ↓
  Terraform runs for 5 minutes
       ↓
  Fails halfway through
       ↓
  Some resources created, some not
       ↓
  Messy state to clean up
       ↓
  20 minutes wasted

With linting:
  Developer pushes broken code
       ↓
  Lint check fails in 5 seconds
       ↓
  "Your code has formatting errors on line 23"
       ↓
  Developer fixes and pushes again
       ↓
  10 seconds wasted
```

---

## The Mobile Development Experience

A unique aspect of this POC was the seamless cross-device experience:

### Real-Time Synchronization

GitHub Codespaces synchronized everything between mobile and desktop browsers:

```
┌─────────────────┐         ┌─────────────────┐
│   iPhone        │◄───────►│   MacBook       │
│   Browser       │  Sync   │   Browser       │
├─────────────────┤         ├─────────────────┤
│ Terminal output │ ═══════ │ Terminal output │
│ File explorer   │ ═══════ │ File explorer   │
│ Code editor     │ ═══════ │ Code editor     │
│ Claude Code     │ ═══════ │ Claude Code     │
└─────────────────┘         └─────────────────┘

Commands typed on phone appeared on desktop instantly (and vice versa)
```

### What This Means

1. **No Local Dependencies**: Everything ran in the cloud - no need to install AWS CLI, Terraform, or any other tools locally

2. **True Mobility**: Could respond to incidents, deploy fixes, and manage infrastructure from anywhere with a browser

3. **Conversation Continuity**: The Claude Code conversation persisted across devices

4. **Touch-Friendly**: VS Code Web in Codespaces worked on mobile devices

---

## Verification Results

### Deployment Verification

```
Website URL: http://claude-codespaces-aws-s3-hello-world-site.s3-website-eu-west-1.amazonaws.com
HTTP Status: 200 OK
CloudWatch Log Entry: "Deployment successful - Commit: 009d279 - Triggered by: formicag"
```

### Teardown Verification (Confirmed Twice)

```
=== FIRST VERIFICATION ===
S3 website bucket:    ✓ DELETED
S3 tfstate bucket:    ✓ DELETED
DynamoDB table:       ✓ DELETED
IAM role:             ✓ DELETED
IAM policy:           ✓ DELETED
CloudWatch log group: ✓ DELETED

=== SECOND VERIFICATION ===
S3 website bucket:    ✓ DELETED (404 Not Found)
S3 tfstate bucket:    ✓ DELETED (404 Not Found)
DynamoDB table:       ✓ DELETED (ResourceNotFoundException)
IAM role:             ✓ DELETED (NoSuchEntity)
IAM policy:           ✓ DELETED (NoSuchEntity)
CloudWatch log group: ✓ DELETED (empty array)
```

---

## How to Recreate This

### Prerequisites

- GitHub account with Codespaces enabled
- AWS account with SSO configured
- Claude Code extension installed in Codespaces

### Step-by-Step

1. **Create a new GitHub repository**

2. **Open in GitHub Codespaces**
   - Click "Code" → "Codespaces" → "Create codespace on main"

3. **Authenticate with AWS**
   ```
   Ask Claude: "Install AWS CLI and help me log in via SSO"

   You'll need:
   - SSO Start URL (e.g., https://your-company.awsapps.com/start)
   - SSO Region (e.g., eu-west-1)
   - Account ID
   - Role name (e.g., AdministratorAccess)
   ```

4. **Deploy the infrastructure**
   ```
   Ask Claude: "Create a static S3 website with Terraform,
   deploy it with GitHub Actions using OIDC,
   and verify it works via CloudWatch"
   ```

5. **Verify the deployment**
   - Check GitHub Actions tab for green checkmark
   - Visit the website URL
   - Check CloudWatch logs

6. **Clean up**
   ```
   Ask Claude: "Remove all AWS resources and confirm they're gone"
   ```

---

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml              # GitHub Actions CI/CD pipeline
│                                    # This is the "hook" that triggers on push
│
├── terraform/
│   ├── bootstrap/                   # Run once manually to set up OIDC
│   │   ├── main.tf                 # OIDC provider, IAM role, state bucket
│   │   ├── variables.tf            # Input variables
│   │   ├── outputs.tf              # Output values (role ARN, etc.)
│   │   ├── providers.tf            # AWS provider configuration
│   │   └── terraform.tfvars        # Variable values
│   │
│   └── website/                     # Deployed by GitHub Actions
│       ├── main.tf                 # S3 bucket, website config, CloudWatch
│       ├── variables.tf            # Input variables
│       ├── outputs.tf              # Output values (website URL, etc.)
│       └── providers.tf            # AWS provider + S3 backend
│
├── website/                         # Static website files
│   ├── index.html                  # Main page
│   ├── error.html                  # 404 page
│   └── styles.css                  # Styling
│
├── .gitignore                       # Files Git should ignore
└── README.md                        # This documentation
```

---

## Security Best Practices Demonstrated

| Practice | How We Did It |
|----------|---------------|
| **No Stored Credentials** | OIDC federation - GitHub proves identity to AWS |
| **Least Privilege** | IAM policies scoped to specific S3 buckets and resources |
| **State Encryption** | Terraform state stored in S3 with encryption enabled |
| **State Locking** | DynamoDB table prevents concurrent modifications |
| **Audit Trail** | CloudWatch logging for all deployments |
| **Code Review** | Plan runs on PRs, Apply only on merge to main |

---

## Technologies Used

| Technology | Purpose | Why We Used It |
|------------|---------|----------------|
| **GitHub Codespaces** | Cloud development environment | Access from any device with a browser |
| **Claude Code** | AI development assistant | Natural language → working code |
| **AWS S3** | Static website hosting | Simple, cheap, scalable hosting |
| **AWS IAM + OIDC** | Secure authentication | No stored credentials |
| **Terraform** | Infrastructure as Code | Declarative, trackable, repeatable |
| **GitHub Actions** | CI/CD automation | Built into GitHub, free tier available |
| **CloudWatch** | Monitoring and logging | Audit trail for deployments |

---

## Key Takeaways

### The Pattern (Memorize This!)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. CODE: Write your infrastructure as text files (.tf, .yml)           │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. PUSH: git push to GitHub                                             │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. HOOK: .github/workflows/*.yml files trigger automatically           │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 4. LINT: Check code quality (formatting, syntax, security)             │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 5. AUTH: OIDC proves GitHub's identity to AWS (no passwords!)          │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 6. PLAN: Terraform shows what WILL change                               │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 7. APPLY: Terraform makes the changes via AWS SDK                       │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ 8. VERIFY: Check the result (website live, logs captured)              │
└─────────────────────────────────────────────────────────────────────────┘
```

### Important Distinctions

| Term | What It Actually Is |
|------|---------------------|
| **AWS CLI** | A tool you type commands into (`aws s3 ls`) |
| **AWS SDK** | A code library that programs use internally |
| **Terraform** | Uses AWS SDK directly, NOT the CLI |
| **GitHub Actions** | Automation that runs when you push code |
| **OIDC** | "Prove who you are without a password" |
| **Linting** | Automated code quality checking |

---

## Conclusion

This repository stands as evidence that the future of cloud development is:
- **Location independent** - Work from any device
- **Device agnostic** - Mobile, tablet, desktop - all the same
- **Conversational** - Natural language replaces CLI memorization
- **AI-assisted** - Complex patterns implemented through dialogue
- **Secure by default** - OIDC, least privilege, no stored secrets

The entire creation, deployment, verification, and teardown of this AWS infrastructure was accomplished through natural language conversation with Claude Code, executed from both mobile and desktop browsers in GitHub Codespaces.

---

*Built entirely using Claude Code in GitHub Codespaces - from conception to deployment to documentation.*
