#!/usr/bin/env bash
# gh_push.sh — push to Ye-Shwethway/Agents-Chat-Room using GitHub App token.
#
# Usage:
#   bash gh_push.sh                    # push current branch
#   bash gh_push.sh --init             # add remote (one-time), then push
set -euo pipefail

WS="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WS"

REPO="Ye-Shwethway/Agents-Chat-Room"

get_token() {
  python3 "$WS/scripts/gh_app_auth.py"
}

if [[ "${1:-}" == "--init" ]]; then
  git remote remove origin 2>/dev/null || true
  TOKEN=$(get_token)
  git remote add origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git"
  echo "remote added"
fi

# Refresh token in remote URL every push
TOKEN=$(get_token)
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.git"

BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push -u origin "$BRANCH"
echo "pushed $BRANCH → $REPO"