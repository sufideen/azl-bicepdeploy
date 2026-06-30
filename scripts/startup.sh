#!/usr/bin/env bash
# Redeploys the resources created by deploy.yml's live "Deploy ALZ" job
# (Governance policy → Logging RG/workspace → Hub Network), without needing
# to push to main / wait on CI. Companion to scripts/teardown.sh.
#
# Usage:
#   ./scripts/startup.sh                 # dry-run: az what-if for all 3 stages
#   ./scripts/startup.sh --yes           # actually deploys (az deployment create)
#
# Requires: az login (or OIDC-authenticated session) with Owner at the
# relevant scopes — same permissions used by the deploy pipelines.

set -euo pipefail

AZURE_REGION="westeurope"
MANAGEMENT_GROUP_ID="${AZURE_MANAGEMENT_GROUP_ID:-corp-workloads}"

DRY_RUN=true

for arg in "$@"; do
  case "$arg" in
    --yes) DRY_RUN=false ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--yes]" >&2
      exit 1
      ;;
  esac
done

run() {
  echo "+ $*"
  eval "$@"
}

DEPLOY_TAG="$(date +%s)"

echo "== ALZ Startup =="
if $DRY_RUN; then
  echo "Mode: DRY RUN (az what-if — no changes will be made). Pass --yes to deploy."
else
  echo "Mode: LIVE — resources will be created/updated."
fi
echo

echo "-- Stage 1: Governance Policies (management group: ${MANAGEMENT_GROUP_ID}) --"
if $DRY_RUN; then
  run "az deployment mg what-if --management-group-id '${MANAGEMENT_GROUP_ID}' --location '${AZURE_REGION}' --template-file ./governance.bicep --parameters ./parameters/governance.bicepparam --no-prompt"
else
  run "az deployment mg create --name 'alz-governance-startup-${DEPLOY_TAG}' --management-group-id '${MANAGEMENT_GROUP_ID}' --location '${AZURE_REGION}' --template-file ./governance.bicep --parameters ./parameters/governance.bicepparam --no-prompt"
fi

echo "-- Stage 2: Platform Logging (subscription scope) --"
if $DRY_RUN; then
  run "az deployment sub what-if --location '${AZURE_REGION}' --template-file ./logging.bicep --parameters ./parameters/logging.bicepparam --no-prompt"
else
  run "az deployment sub create --name 'alz-logging-startup-${DEPLOY_TAG}' --location '${AZURE_REGION}' --template-file ./logging.bicep --parameters ./parameters/logging.bicepparam --no-prompt"
fi

echo "-- Stage 3: Hub Network (subscription scope) --"
if $DRY_RUN; then
  run "az deployment sub what-if --location '${AZURE_REGION}' --template-file ./network.bicep --parameters ./parameters/network.bicepparam --no-prompt"
else
  run "az deployment sub create --name 'alz-network-startup-${DEPLOY_TAG}' --location '${AZURE_REGION}' --template-file ./network.bicep --parameters ./parameters/network.bicepparam --no-prompt"
fi

echo
if $DRY_RUN; then
  echo "Dry run complete. Re-run with --yes to deploy these stages."
else
  echo "Startup deployment complete. Run scripts/teardown.sh when done to remove billable resources."
fi
