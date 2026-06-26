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