#!/usr/bin/env bash
# Tears down the billable resources created by deploy.yml (and optionally
# the Management Group hierarchy created by deploy-tenant.yml).
#
# Usage:
#   ./scripts/teardown.sh                       # dry-run, prints commands only
#   ./scripts/teardown.sh --yes                  # actually deletes RG-scoped resources
#   ./scripts/teardown.sh --yes --include-mgmt-groups   # also deletes the MG hierarchy
#
# Requires: az login (or OIDC-authenticated session) with Owner at the
# relevant scopes — same permissions used by the deploy pipelines.

set -euo pipefail

CONNECTIVITY_RG="rg-ict-connectivity-prod"
LOGGING_RG="rg-ict-management-poc"
MANAGEMENT_GROUP_ID="${AZURE_MANAGEMENT_GROUP_ID:-corp-workloads}"
POLICY_ASSIGNMENT_NAME="alz-allowed-locations-${MANAGEMENT_GROUP_ID}"

ROOT_MG="corp"
CHILD_MGS=("corp-platform" "corp-connectivity" "corp-identity" "corp-management" "corp-workloads" "corp-production" "corp-nonprod" "corp-sandbox" "corp-decommissioned")

DRY_RUN=true
INCLUDE_MGMT_GROUPS=false

for arg in "$@"; do
  case "$arg" in
    --yes) DRY_RUN=false ;;
    --include-mgmt-groups) INCLUDE_MGMT_GROUPS=true ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--yes] [--include-mgmt-groups]" >&2
      exit 1
      ;;
  esac
done

run() {
  if $DRY_RUN; then
    echo "[dry-run] $*"
  else
    echo "+ $*"
    eval "$@"
  fi
}

echo "== ALZ Teardown =="
if $DRY_RUN; then
  echo "Mode: DRY RUN (no changes will be made). Pass --yes to execute."
else
  echo "Mode: LIVE — resources will be deleted."
fi
echo

echo "-- Stage 1: Hub Network (resource group: ${CONNECTIVITY_RG}) --"
run "az group delete --name '${CONNECTIVITY_RG}' --yes --no-wait"

echo "-- Stage 2: Platform Logging (resource group: ${LOGGING_RG}) --"
run "az group delete --name '${LOGGING_RG}' --yes --no-wait"

echo "-- Stage 3: Governance Policy Assignment (management group: ${MANAGEMENT_GROUP_ID}) --"
run "az policy assignment delete --name '${POLICY_ASSIGNMENT_NAME}' --management-group '${MANAGEMENT_GROUP_ID}'"

if $INCLUDE_MGMT_GROUPS; then
  echo "-- Stage 4: Management Group Hierarchy (tenant scope) --"
  echo "Deleting children before parents — Azure requires management groups to be empty."
  for mg in "${CHILD_MGS[@]}"; do
    run "az account management-group delete --name '${mg}'"
  done
  run "az account management-group delete --name '${ROOT_MG}'"
else
  echo "-- Stage 4: Management Group Hierarchy — skipped (pass --include-mgmt-groups to remove) --"
fi

echo
if $DRY_RUN; then
  echo "Dry run complete. Re-run with --yes to execute these commands."
else
  echo "Teardown commands submitted. Resource group deletions are asynchronous (--no-wait)."
  echo "Check progress with: az group list --query \"[?name=='${CONNECTIVITY_RG}' || name=='${LOGGING_RG}']\""
fi
