using '../governance.bicep'

// ── Governance / Policy Parameters ────────────────────────────────────────────
// managementGroupId must match the --management-group-id argument passed to
// `az deployment mg create`. It is used for documentation only — the actual
// deployment scope is set by the CLI, not this parameter.

param managementGroupId = 'corp-workloads'
