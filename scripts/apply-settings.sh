#!/usr/bin/env bash
# usage: scripts/apply-settings.sh base|strict
set -euo pipefail
mode="${1:?base or strict}"
repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
cd "$(git rev-parse --show-toplevel)"

gh api -X PATCH "repos/$repo" --input settings/repo.json >/dev/null
id="$(gh api "repos/$repo/rulesets" --jq '.[] | select(.name == "protect-main") | .id')"
if [ -n "$id" ]; then
  gh api -X PUT "repos/$repo/rulesets/$id" --input "settings/ruleset-$mode.json" >/dev/null
else
  gh api -X POST "repos/$repo/rulesets" --input "settings/ruleset-$mode.json" >/dev/null
fi

if [ "$mode" = strict ]; then
  gh api -X PATCH "repos/$repo" -F allow_auto_merge=true >/dev/null
  gh api -X PUT "repos/$repo/actions/permissions/workflow" \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true
  gh api -X PUT "repos/$repo/vulnerability-alerts"
  gh api -X PUT "repos/$repo/automated-security-fixes"
else
  gh api -X PUT "repos/$repo/actions/permissions/workflow" \
    -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
  gh api -X DELETE "repos/$repo/automated-security-fixes" || true
  gh api -X DELETE "repos/$repo/vulnerability-alerts" || true
fi
echo "applied: $mode -> $repo"
