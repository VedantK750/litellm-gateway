#!/usr/bin/env bash
# Generate a per-peer virtual key with a budget + rate limits.
# Usage:
#   PROXY=https://litellm-gateway.onrender.com MASTER_KEY=sk-... ./gen-key.sh alice 20 100 40000
# Args: <peer-name> [budget_usd=20] [rpm=100] [tpm=40000]
set -euo pipefail

: "${PROXY:?set PROXY to your Render URL, e.g. https://litellm-gateway.onrender.com}"
: "${MASTER_KEY:?set MASTER_KEY to your LITELLM_MASTER_KEY}"

NAME="${1:?usage: ./gen-key.sh <peer-name> [budget_usd] [rpm] [tpm]}"
BUDGET="${2:-20}"
RPM="${3:-100}"
TPM="${4:-40000}"

curl -sS -X POST "$PROXY/key/generate" \
  -H "Authorization: Bearer $MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d @- <<JSON
{
  "key_alias": "$NAME",
  "max_budget": $BUDGET,
  "budget_duration": "30d",
  "rpm_limit": $RPM,
  "tpm_limit": $TPM
}
JSON
echo
echo "^ hand the \"key\" value above to $NAME (revoke later via the /ui dashboard)."
