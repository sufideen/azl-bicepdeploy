# Azure Landing Zone (ALZ) Multi-Scope GitOps Engine

A fully automated, production-aligned Azure Landing Zone (ALZ) infrastructure-as-code blueprint, deployed via **Bicep** and **GitHub Actions** using passwordless OpenID Connect (OIDC) authentication.

---

## Overview

This blueprint spans four distinct Azure deployment scopes to enforce governance, platform operations, and enterprise networking from a single GitOps pipeline.

| Deployment Layer    | Scope             | Primary Resource Types                              | Purpose                                                  |
| :------------------ | :---------------- | :------------------------------------------------- | :------------------------------------------------------- |
| **Tenant / Root**   | `tenant`          | Management Groups (`/managementGroups/<root-id>`)  | Establishes the organizational hierarchy.                |
| **Governance**      | `managementGroup` | Policy Definitions & Assignments                   | Restricts resource deployment to compliant regions.      |
| **Shared Platform** | `resourceGroup`   | Log Analytics Workspaces, Microsoft Sentinel       | Aggregates operational telemetry and security logs.      |
| **Network Edge**    | `subscription`    | Hub Virtual Network (VNet) & system subnets        | Orchestrates central routing (Firewall, Bastion, Gateways). |

---

## Prerequisites

- An active **Azure subscription** with rights to assign roles at the root management group scope.
- **Azure CLI** (`az`) authenticated to your tenant (`az login`).
- The **Bicep CLI** (bundled with recent Azure CLI versions).
- A **GitHub repository** and a Personal Access Token (PAT) for CLI pushes.

---

## Implementation Guide

Follow these phases sequentially to build, secure, and automate the infrastructure framework.

### Phase A — Local Workspace Initialization

Initialize a clean local Git repository and configure your identity:

```bash
# Initialize local Git tracking
git init

# Rename the default branch to align with GitHub
git branch -M main

# Configure your Git identity
git config --global user.name "your-github-username"
git config --global user.email "your-professional-email@domain.com"
```

### Phase B — Identity & Root Permissions

Register a dedicated platform application in Microsoft Entra ID to enable passwordless automation via OIDC.

```bash
# 1. Create the Entra ID Application Registration
az ad app create --display-name "github-actions-alz-deploy"
#    From the JSON output, copy the 'appId' value — this is your Client ID.
#    Keep it handy, but never commit it to public code.

# 2. Create a Service Principal for the new Application ID
az ad sp create --id "YOUR_AZURE_CLIENT_ID"

# 3. Grant Owner at the root Management Group scope
az role assignment create \
  --assignee "YOUR_AZURE_CLIENT_ID" \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/YOUR_ROOT_MANAGEMENT_GROUP_ID"
```

### Phase C — OIDC Trust Relationship

Rather than storing client secrets, define an explicit trust policy with GitHub. Create a local file named `credential.json`:

```json
{
  "name": "github-actions-oidc-trust",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:YOUR_GITHUB_ORG_OR_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main",
  "description": "Allows GitHub Actions main branch to deploy ALZ infrastructure",
  "audiences": ["api://AzureADTokenExchange"]
}
```

Apply the federation link to your app identity:

```bash
az ad app federated-credential create \
  --id "YOUR_AZURE_CLIENT_ID" \
  --parameters ./credential.json
```

This binds your repository's `main` branch to your Azure identity, allowing short-lived tokens to handle authorization without stored secrets.

### Phase D — GitHub Repository Secrets

Populate the repository secrets so the runner can target your workspace without exposing credentials.

Navigate to **Settings → Secrets and variables → Actions**, then click **New repository secret** to add:

| Secret Name             | Value                                              |
| :---------------------- | :------------------------------------------------- |
| `AZURE_CLIENT_ID`       | App Registration / Client ID from Phase B          |
| `AZURE_TENANT_ID`       | Microsoft Entra Tenant ID                          |
| `AZURE_SUBSCRIPTION_ID` | Target Azure Subscription ID                       |

### Phase E — Deploy the Pipeline Engine

Create the workflow directory and add the deployment workflow:

```bash
mkdir -p .github/workflows
```

Create `.github/workflows/deploy.yml`:

```yaml
name: "Azure ALZ GitOps Deployment"

on:
  push:
    branches: [ main ]

permissions:
  id-token: write
  contents: read

jobs:
  validate_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Azure Login via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Run Bicep Lint Check
        run: az bicep build --file ./network.bicep

      - name: Azure Deployment Dry-Run (What-If)
        uses: azure/arm-deploy@v2
        with:
          scope: subscription
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          region: westeurope
          template: ./network.bicep
          additionalArguments: --what-if
```

### Phase F — Sync and Launch

If the remote repository already contains files (e.g. a `README.md` or `LICENSE`), reconcile histories before pushing:

```bash
# 1. Link the remote repository
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git

# 2. Merge unrelated histories
git config pull.rebase false
git pull origin main --allow-unrelated-histories

# 3. Stage, commit, and push
git add .
git commit -m "feat: secure multi-scope baseline with OIDC automation engine"
git push -u origin main
```

> **Note on credentials:** When prompted for a password during CLI pushes, use your GitHub Personal Access Token (PAT) — not your account password.

---

## Verifying the Deployment

After pushing, confirm the pipeline ran successfully:

1. Open the **Actions** tab in your GitHub repository.
2. Select the latest workflow run for your commit.
3. Open the `validate_and_deploy` job to watch the live logs.

A green checkmark confirms that your Bicep files compiled, passed the data-residency policy guardrails, and resolved the production Hub Virtual Network subnets.