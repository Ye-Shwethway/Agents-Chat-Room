#!/usr/bin/env bash
# git_push.sh — alias for gh_push.sh
bash "$(dirname "$0")/gh_push.sh" "${@:-}"