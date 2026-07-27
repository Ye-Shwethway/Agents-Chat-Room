#!/usr/bin/env bash
# gh_api.sh — fetch GitHub API with auto-refreshed installation token.
#
# Usage:
#   bash scripts/gh_api.sh GET /repos/OWNER/REPO/actions/runs?per_page=1
#   bash scripts/gh_api.sh GET /repos/OWNER/REPO/actions/runs/RUN_ID/jobs
set -euo pipefail

WS="$(cd "$(dirname "$0")/.." && pwd)"
TOKEN=*** "$WS/scripts/gh_app_auth.py")
METHOD="${1:-GET}"
PATH_="${2:-/}"

curl -s -X "$METHOD" \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com${PATH_}"