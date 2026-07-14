# Daily Operations Runbook — Azure Cloud Engineer

This checklist covers the recurring, day-to-day tasks for operating the Azure Landing Zone
platform defined in this repository (management group governance, hub network, centralized
logging, and VM security onboarding). It complements [ARCHITECTURE.md](ARCHITECTURE.md), which
describes *what* is deployed — this document describes the ongoing work of *running* it.

---

## Pipeline & Deployment

- [ ] Review the latest `deploy.yml` run (Lint → Validate/what-if → Deploy) for failures
- [ ] Triage any `AuthorizationFailed`, policy-deny, or `bicep build` lint errors before they block `main`
- [ ] Review and merge open PRs touching `*.bicep` / `*.bicepparam` files, checking the `what-if`
      diff for unintended scope changes or resource drift
- [ ] Confirm any `deploy-tenant.yml` runs (Management Group hierarchy changes) went through
      tenant-root approval — treat these as exceptional, not routine, work

## Governance & Compliance

- [ ] Check Azure Policy compliance state (`az policy state list`) for the
      `alz-allowed-locations` assignment and any other active policies
- [ ] Investigate and remediate non-compliant resources
- [ ] Review Activity Log for policy-deny events (deployments blocked outside
      `westeurope` / `uksouth`)
- [ ] Spot-check RBAC / role assignments at management-group and subscription scope for
      drift or excess permissions

## Logging & Security Monitoring

- [ ] Verify Log Analytics (`log-ict-poc-shared`) ingestion health and data volume
- [ ] Confirm diagnostic settings / DCRs (`modules/security-events-dcr.bicep`,
      `modules/activity-log-diagnostics.bicep`) are still linked to newly deployed resources
- [ ] Review Microsoft Sentinel / Defender for Cloud alerts (once onboarded), or run manual
      `SecurityEvent` / `AzureActivity` KQL queries in the interim
- [ ] Validate VM monitoring onboarding (`modules/vm-monitoring-onboarding.bicep`,
      `modules/security-solution.bicep`) for any newly deployed VMs — confirm the Azure
      Monitor Agent connected and is reporting

## Networking

- [ ] Monitor hub VNet (`vnet-ict-hub-prod`) subnet utilization
- [ ] Review NSG / Azure Firewall logs (once the firewall is deployed per the roadmap in the
      main [README](../README.md#next-steps))
- [ ] Review incoming spoke VNet peering requests against the `hubVnetId` output

## Identity & OIDC Hygiene

- [ ] Confirm the federated credential (`credential.json`) still scopes to `refs/heads/main` only
- [ ] Confirm no secrets have been committed (`.env`, `*.psat`, `.azure/`, etc.)
- [ ] Review App Registration permissions when new subscriptions or scopes are added

## Cost & Housekeeping

- [ ] Spot-check Log Analytics retention/ingestion cost against budget (PerGB2018 SKU)
- [ ] Groom the platform backlog (Sentinel, Defender for Cloud, Azure Firewall, spoke peering,
      Private DNS Zones, DDoS Protection Standard, budget alerts) — see
      [README § Next Steps](../README.md#next-steps) — and pick up the next unimplemented item

---

*This is a living checklist — update it as new modules, policies, or pipeline stages are added.*
