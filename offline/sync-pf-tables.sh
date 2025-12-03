#!/usr/bin/env bash
# Sync PF tables with current Tailscale DERP endpoints and update hosts
set -euo pipefail

# Check for root - don't preserve environment for security
if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

echo "=== Syncing PF Tables ==="

resolve_hosts() {
  local table_name="$1"
  shift
  local hosts=("$@")
  local resolved=0
  local failed=0

  pfctl -t "$table_name" -T flush 2>/dev/null || true

  for host in "${hosts[@]}"; do
    if ips=$(dig +short "$host" A 2>/dev/null | grep -E '^[0-9]+\.' | head -5); then
      if [[ -n "$ips" ]]; then
        while read -r ip; do
          pfctl -t "$table_name" -T add "$ip" 2>/dev/null && ((resolved++)) || true
        done <<< "$ips"
      else
        ((failed++))
      fi
    else
      ((failed++))
    fi
  done

  echo "  Resolved $resolved IPs ($failed hosts failed)"
}

# --- Tailscale DERP endpoints ---
echo "Fetching Tailscale DERP endpoints..."
DERP_HOSTS=$(curl -sf https://controlplane.tailscale.com/derpmap/default 2>/dev/null | \
  python3 -c '
import json,sys
data=json.load(sys.stdin)
for region in data["Regions"].values():
    for node in region.get("Nodes", []):
        if "HostName" in node:
            print(node["HostName"])
' || echo "")

CORE_HOSTS=(
  "login.tailscale.com"
  "controlplane.tailscale.com"
  "controlplane.tailscale.net"
  "api.tailscale.com"
  "control.tailscale.com"
)

if [[ -z "$DERP_HOSTS" ]]; then
  echo "⚠️  Failed to fetch DERP endpoints; using core hosts only"
  ALL_TS_HOSTS=("${CORE_HOSTS[@]}")
else
  echo "✓ Found $(echo "$DERP_HOSTS" | wc -l | tr -d ' ') DERP endpoints"
  mapfile -t DERP_ARRAY <<< "$DERP_HOSTS"
  ALL_TS_HOSTS=("${CORE_HOSTS[@]}" "${DERP_ARRAY[@]}")
fi

echo "Resolving tailscale_hosts..."
resolve_hosts "tailscale_hosts" "${ALL_TS_HOSTS[@]}"

# --- LM Studio / Hugging Face hosts ---
LMSTUDIO_HOSTS=(
  "lmstudio.ai"
  "huggingface.co"
  "hf.co"
  "cdn-lfs.huggingface.co"
  "cdn-lfs.hf.co"
  "cdn-lfs-us-1.hf.co"
  "cdn-lfs-eu-1.hf.co"
  "cdn-lfs-us-1.huggingface.co"
  "cdn-lfs-eu-1.huggingface.co"
  "cas-bridge.xethub.hf.co"
  "transfer.xethub.hf.co"
  "cas-server.xethub.hf.co"
)

echo "Resolving lmstudio_hosts..."
resolve_hosts "lmstudio_hosts" "${LMSTUDIO_HOSTS[@]}"

# --- Update hosts (GitHub, Homebrew, etc.) ---
UPDATE_HOSTS=(
  "github.com"
  "api.github.com"
  "raw.githubusercontent.com"
  "objects.githubusercontent.com"
  "ghcr.io"
  "pkg-containers.githubusercontent.com"
  "formulae.brew.sh"
  "homebrew.bintray.com"
)

echo "Resolving update_hosts..."
resolve_hosts "update_hosts" "${UPDATE_HOSTS[@]}"

# --- Package repos ---
PACKAGE_HOSTS=(
  "pypi.org"
  "files.pythonhosted.org"
  "registry.npmjs.org"
  "registry.yarnpkg.com"
  "crates.io"
  "static.crates.io"
  "index.crates.io"
  "golang.org"
  "proxy.golang.org"
  "pkg.go.dev"
  "sum.golang.org"
  "dl.google.com"
)

echo "Resolving package_repos..."
resolve_hosts "package_repos" "${PACKAGE_HOSTS[@]}"

# --- Summary ---
echo ""
echo "=== Table Summary ==="
for table in tailscale_hosts lmstudio_hosts update_hosts package_repos; do
  count=$(pfctl -t "$table" -T show 2>/dev/null | wc -l | tr -d ' ')
  echo "  $table: $count IPs"
done

logger -t offline-firewall "PF tables synced"
echo ""
echo "✓ All tables synced"
