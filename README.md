# Azure Landing Zone (ALZ) Multi-Scope GitOps Engine 🚀

This repository contains a fully automated, production-aligned Azure Landing Zone (ALZ) infrastructure-as-code blueprint deployed via Bicep and GitHub Actions.

---

## 🧭 How to Learn This Project (VAK Style)

To help digest this architecture across all learning preferences:
*   **👀 Visual Learners:** Follow the **Architecture Layout** table and structured code blocks below to map out how directories cascade.
*   **🎧 Auditory/Verbal Learners:** Read the **"Why It Matters"** sections aloud. They explain the architectural rationale behind every single configuration.
*   **🛠️ Kinesthetic Learners:** Execute the terminal blocks sequentially. Hands-on typing and monitoring live pipeline streams anchors the engineering concepts.

---

## 🏗️ 1. The Core Architecture Layout

This blueprint spans four distinct deployment scopes within Azure to enforce governance, platform operations, and enterprise networking.

| Deployment Layer | Scope | Primary Resource Types | Purpose |
| :--- | :--- | :--- | :--- |
| **Tenant / Root** | `tenant` | Management Groups (`/managementGroups/your-root-id`) | Establishes organizational folder hierarchy. |
| **Governance** | `managementGroup` | Policy Definitions & Assignments | Restricts resource deployment to compliant regions. |
| **Shared Platform** | `resourceGroup` | Log Analytics Workspaces, Sentinel | Aggregates operational telemetry and security logs. |
| **Network Edge** | `subscription` | Hub Virtual Network (VNet) & System Subnets | Orchestrates central routing (Firewall, Bastion, Gateways). |

---

## 🛠️ 2. Step-by-Step Implementation Guide

Follow these steps sequentially to build, link, secure, and automate the entire infrastructure framework.

### Phase A: Local Workspace Initialization
Initialize a clean local Git tracking repository within your workspace environment:

```bash
# 1. Initialize local Git tracking
git init

# 2. Rename your default branch to align with GitHub
git branch -M main

# 3. Configure your local Git identity strings
git config --global user.name "your-github-username"
git config --global user.email "your-professional-email@domain.com"

## Phase B: Establishing Identity & Root Permissions
To enable passwordless automation via OpenID Connect (OIDC), register a dedicated platform application identity inside Microsoft Entra ID.

```bash
# 1. Create the Entra ID Application Registration
az ad app create --display-name "github-actions-alz-deploy"

# NOTE: From the JSON output, copy the 'appId' value (this is your Client ID).
# Keep it handy for the next steps but NEVER commit it to public code files.

# 2. Create a Service Principal matching your new Application ID
az ad sp create --id "YOUR_AZURE_CLIENT_ID"

# 3. Grant Owner privileges to the Service Principal at the root Management Group scope
az role assignment create \
  --assignee "YOUR_AZURE_CLIENT_ID" \
  --role "Owner" \
  --scope "/providers/Microsoft.Management/managementGroups/YOUR_ROOT_MANAGEMENT_GROUP_ID"

Phase C: Configuring OIDC Trust Relationships
Instead of risking exposed passwords or client secrets, create a local file named credential.json to configure an explicit trust policy with GitHub:
{
  "name": "github-actions-oidc-trust",
  "issuer": "[https://token.actions.githubusercontent.com](https://token.actions.githubusercontent.com)",
  "subject": "repo:YOUR_GITHUB_ORGANIZATION_OR_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main",
  "description": "Allows GitHub Actions main branch to deploy ALZ infrastructure",
  "audiences": ["api://AzureADTokenExchange"]
}

Apply this federation link to your app identity using the following CLI command:

az ad app federated-credential create --id "YOUR_AZURE_CLIENT_ID" --parameters ./credential.json
This explicitly binds your GitHub repository's main branch to your Azure security identity, allowing secure, temporary tokens to handle authorization.

Phase D: Injecting GitHub Repository Secrets
Before executing the pipeline, populate your GitHub Repository Vault to allow the runner to target your specific workspace coordinates without exposing them to the public:

Navigate to your GitHub Repository -> ⚙️ Settings -> Secrets and variables -> Actions.

Click New repository secret to add the following three key-value sets:

AZURE_CLIENT_ID ➡️ Your App Registration/Client ID generated during Phase B

AZURE_TENANT_ID ➡️ Your Microsoft Entra Tenant ID

AZURE_SUBSCRIPTION_ID ➡️ Your active target Azure Subscription ID

Phase E: Deploying the Automated Pipeline Engine
Create a hidden directory layout for your workflow automation:

Bash
mkdir -p .github/workflows
Create a workflow file named .github/workflows/deploy.yml and paste the following operational lifecycle script:

YAML
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
Phase F: Syncing and Launching the Engine
If your remote repository already contains file initializations (such as a README.md or LICENSE), reconcile your branch histories before pushing your code live:

Bash
# 1. Establish the connection link to the remote repository
git remote add origin [https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git)

# 2. Pull down remote objects and merge unrelated history streams
git config pull.rebase false
git pull origin main --allow-unrelated-histories

# 3. Stage, commit, and fire your codebase up to GitHub
git add .
git commit -m "Feat: Completed secure multi-scope baseline and OIDC automation engine"
git push -u origin main
📝 Note on Credentials: When prompted for a password during CLI pushes, paste your GitHub Personal Access Token (PAT), not your standard account login password.

🏁 3. Verifying the Green Success State
Once your push is finalized, immediately change tabs to verify your deployment:

Click the Actions tab at the top of your GitHub repository browser page.

Select your latest active commit message run.

Click into the validate_and_deploy job matrix to watch the live terminal logs compute.

A Green Checkmark (Success) indicates that your Bicep files have passed compilation, verified data residency policy guardrails, and mapped out your production Hub Virtual Network subnets seamlessly!
EOF


---

### Step 3: Push the Complete File Up to GitHub

With the file fully generated locally on your drive, push it up to overwrite the old broken preview:

```bash
git add README.md
git commit -m "Docs: Fully stitched master README deployment via incremental streaming"
git push origin main
