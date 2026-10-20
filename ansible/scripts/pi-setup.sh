#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/admin}"
export PI_CODING_AGENT_DIR="${PI_CODING_AGENT_DIR:-${HOME}/.pi/agent}"

for package in \
  npm:billion-context-pi \
  npm:pi-subagents \
  npm:pi-web-access; do
  pi install "${package}"
done

mkdir -p "${HOME}/.pi"
acp_config="${HOME}/.pi/acp.json"
if [ -f "${acp_config}" ]; then
  tmp="$(mktemp)"
  jq '.delegate = false' "${acp_config}" > "${tmp}"
  mv "${tmp}" "${acp_config}"
else
  printf '{\n  "delegate": false\n}\n' > "${acp_config}"
fi

hindsight-coding-agents install pi \
  --server self-hosted \
  --api-url "${HINDSIGHT_API_URL:-http://127.0.0.1:8888}"

hindsight_config="${HOME}/.hindsight/coding-agent.json"
mkdir -p "${HOME}/.hindsight"
if [ ! -f "${hindsight_config}" ]; then
  jq -n --arg api "${HINDSIGHT_API_URL:-http://127.0.0.1:8888}" \
    '{apiUrl: $api}' > "${hindsight_config}"
fi
tmp="$(mktemp)"
jq '.bankId = "opencode" | .manageBankConfig = false' \
  "${hindsight_config}" > "${tmp}"
mv "${tmp}" "${hindsight_config}"

pi list
