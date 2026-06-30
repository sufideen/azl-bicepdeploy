# Security Policy

## Supported Scope

This repository contains **infrastructure-as-code (IaC)** only — Bicep templates and a GitHub Actions pipeline. There is no application runtime or API surface.

## Security Posture

### No Stored Credentials

This project uses **OpenID Connect (OIDC) federated identity** for all Azure deployments. GitHub Actions exchanges a short-lived, cryptographically-signed token with Microsoft Entra ID at runtime. No client secrets, passwords, or long-lived tokens are stored anywhere in this repository.

- The trust binding is declared in `credential.json` (issuer + subject claim only — no secret material).
- The three GitHub Secrets (`AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`) are identifiers, not credentials.

### Principle of Least Privilege

- The Entra ID application registration is granted `Owner` at the **root Management Group** scope only — the minimum required to deploy cross-scope ALZ resources.
- The OIDC trust is scoped strictly to the `main` branch (`ref:refs/heads/main`). Feature branches cannot authenticate.
- Log Analytics access is enforced via RBAC (`enableLogAccessUsingOnlyResourcePermissions: true`).

### Data Residency Enforcement

The `governance.bicep` policy assignment actively **denies** any Azure resource deployment outside `westeurope` and `uksouth`. This is a hard guard, not an audit-only control.

### Supply Chain Integrity

- GitHub Actions steps pin to versioned release tags (`actions/checkout@v4`, `azure/login@v2`, `azure/arm-deploy@v2`).
- The Hub VNet is deployed via the **Azure Verified Module** (AVM) registry (`br/public:avm/res/network/virtual-network:0.5.1`) — a Microsoft-curated, audited module source.

### .gitignore Protections

The following sensitive file patterns are excluded from version control:

```
.env
*.psat
*.secret.bicepdefaults
.azure/
```

## Reporting a Vulnerability

If you discover a security issue (e.g. a template that grants overly broad permissions, a misconfigured policy, or an insecure CI/CD pattern):

1. **Do not open a public GitHub issue.**
2. Email the repository owner directly, or use GitHub's private [Security Advisory](https://docs.github.com/en/code-security/security-advisories/working-with-repository-security-advisories/creating-a-repository-security-advisory) feature.
3. Include: a description of the issue, reproduction steps, and potential impact.

A response will be provided within **5 business days**.
