# Architecture Reference

This document is the single-page technical reference for the **Azure Landing Zone (ALZ) Multi-Scope GitOps Engine** — a production-aligned infrastructure-as-code blueprint spanning four Azure deployment scopes (tenant, management group, subscription, resource group), deployed via Bicep and GitHub Actions using passwordless OIDC authentication.

---

## Diagrams

### 1. Overall Architecture — All Four Scopes

Shows the complete ALZ stack: Management Group hierarchy at tenant scope, data-residency policy at management group scope, Hub VNet at subscription scope, and Log Analytics at resource group scope — all driven by a single GitHub Actions pipeline.

![Architecture Overview](./architecture-overview.svg)

| Layer | Scope | Bicep File |
|:---|:---|:---|
| Tenant / Root | `tenant` | `deploy.bicep` |
| Governance | `managementGroup` | `governance.bicep` |
| Shared Platform | `resourceGroup` (via subscription module) | `logging.bicep` → `modules/log-workspace.bicep` |
| Network Edge | `subscription` | `network.bicep` |

---

### 2. Management Group Hierarchy

Ten management groups structured in three tiers: root → platform services → workload environments. All child subscriptions inherit Azure Policy and RBAC assignments from their parent nodes automatically.

![Management Group Hierarchy](./management-group-hierarchy.svg)

| Management Group | Parent | Purpose |
|:---|:---|:---|
| `corp` | Tenant root | Organisation root node |
| `corp-platform` | corp | Shared infrastructure services |
| `corp-connectivity` | corp-platform | Hub networks, Firewalls, Gateways |
| `corp-identity` | corp-platform | Active Directory, Key Vaults |
| `corp-management` | corp-platform | Log Analytics, Automation |
| `corp-workloads` | corp | Application workload subscriptions |
| `corp-production` | corp-workloads | Production environments |
| `corp-nonprod` | corp-workloads | Non-production / testing |
| `corp-sandbox` | corp | Developer playgrounds |
| `corp-decommissioned` | corp | Legacy / retired resources |

---

### 3. Hub Virtual Network Topology

Central hub VNet (`10.0.0.0/22`) with four reserved subnets. Subnet names are mandatory — Azure services (Firewall, Gateway, Bastion) require exact naming to provision correctly. The hub VNet outputs `hubVnetId` for spoke VNet peering modules.

![Hub Network Topology](./hub-network-topology.svg)

| Subnet | CIDR | Hosted Service | Naming Constraint |
|:---|:---|:---|:---|
| `AzureFirewallSubnet` | `10.0.0.0/24` | Azure Firewall | Mandatory exact name |
| `GatewaySubnet` | `10.0.1.0/24` | VPN / ExpressRoute Gateway | Mandatory exact name |
| `AzureBastionSubnet` | `10.0.2.0/24` | Azure Bastion | Mandatory exact name |
| `snet-shared-management` | `10.0.3.0/24` | Management agents, Automation | Custom |

---

### 4. CI/CD Pipeline Flow

Three-job GitHub Actions pipeline. Lint runs without Azure credentials. Validate runs a What-If dry-run across all four deployment scopes on every push and PR. Deploy executes the live four-stage deployment only on merge to `main`.

![CI/CD Pipeline](./cicd-pipeline.svg)

| Job | Trigger | Steps |
|:---|:---|:---|
| **Lint** | Every push & PR | `bicep build` on all 5 Bicep files |
| **Validate** | Every push & PR (needs Lint) | `what-if` across Tenant → MG → Sub (Logging) → Sub (Network) |
| **Deploy** | Push to `main` only (needs Validate) | Live deploy of all 4 scopes in sequence |

---

## Screenshots

> All screenshots below are from the live deployed platform, except the GitHub Actions run, which is a mockup modeled on a real pipeline run (`.svg`, since pipeline UI changes over time). To refresh it, take a new screenshot → save as `.png` → replace `docs/screenshots/github-actions-run.svg` → commit. Both `.png` and `.svg` are supported by GitHub Markdown rendering.

### GitHub Actions — Successful Pipeline Run

Shows the three-job pipeline (Bicep Lint, What-If Validation, Deploy ALZ) passing with green checkmarks, each staged across Management Group, Subscription, and Hub Network scopes.

![GitHub Actions Run](./screenshots/github-actions-run.svg)

See the real run: [Azure ALZ GitOps Deployment #28455413091](https://github.com/sufideen/azl-bicepdeploy/actions/runs/28455413091)

---

### Azure Portal — Hub Virtual Network

Shows `vnet-ict-hub-prod` in the Azure Portal with address space `10.0.0.0/22` and all four subnets listed.

![Azure Portal — Hub VNet](./screenshots/azure-portal-vnet.png)

---

### Azure Portal — Policy Assignment

Shows the `alz-allowed-locations` policy assignment at management group scope with compliance state and the two permitted regions.

![Azure Portal — Policy](./screenshots/azure-portal-policy.png)

![Azure Portal — Policy Detail](./screenshots/azure-portal-policy-02.png)

---

### Azure Portal — Log Analytics Workspace

Shows `log-ict-poc-shared` in the Azure Portal with SKU, retention period, and connected data sources.

![Azure Portal — Log Analytics](./screenshots/log-ict-poc-shared.png)

![Azure Portal — Log Analytics Query Results](./screenshots/log-ict-poc-shared02.png)

---

## File Reference Map

| Diagram / Screenshot | Documents | Source File |
|:---|:---|:---|
| `architecture-overview.svg` | Full ALZ deployment topology | All four Bicep files |
| `management-group-hierarchy.svg` | Org governance structure | `deploy.bicep` |
| `hub-network-topology.svg` | Hub VNet subnets and services | `network.bicep` |
| `cicd-pipeline.svg` | GitHub Actions workflow | `.github/workflows/deploy.yml` |
| `screenshots/github-actions-run.svg` | Pipeline run mockup (modeled on run #28455413091) | `.github/workflows/deploy.yml` |
| `screenshots/azure-portal-vnet.png` | Deployed hub VNet | `network.bicep` |
| `screenshots/azure-portal-policy.png` | Active policy assignment | `governance.bicep` |
| `screenshots/log-ict-poc-shared.png` | Deployed workspace + live SecurityEvent query results | `logging.bicep` + `modules/log-workspace.bicep` |
| `screenshots/log-ict-poc-shared02.png` | Deployed workspace + live SecurityEvent query results | `logging.bicep` + `modules/log-workspace.bicep` |
