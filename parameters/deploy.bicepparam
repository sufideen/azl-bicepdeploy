using '../deploy.bicep'

// ── Management Group Hierarchy Parameters ─────────────────────────────────────
// These values define the naming prefix and display name for the entire tenant
// management group tree. Changing orgPrefix renames every management group.

param orgPrefix = 'corp'
param orgDisplayName = 'Contoso Holdings'
