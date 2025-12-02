#!/usr/bin/env bash
# Sync PF tables with current Tailscale DERP endpoints
set -euo pipefail

# Check for root
if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

echo "=== Syncing PF Tables ==="

# Fetch Tailscale DERP map
echo "Fetching Tailscale DERP endpoints..."
DERP_HOSTS=$(curl -sf https://controlplane.tailscale.com/derpmap/default 2>/dev/null | \
  python3 -c 'import json,sys; data=json.load(sys.stdin); print("\n".join([r["HostName"] for r in data["Regions"].values()]))' || echo "")

if [[ -z "$DERP_HOSTS" ]]; then
  echo "⚠️  Failed to fetch DERP endpoints; keeping existing table"
else
  echo "✓ Found $(echo "$DERP_HOSTS" | wc -l | tr -d ' ') DERP endpoints"

  # Update tailscale_hosts table
  # Keep the core control plane hosts and add DERP endpoints
  CORE_HOSTS="login.tailscale.com
controlplane.tailscale.com
controlplane.tailscale.net
api.tailscale.com
control.tailscale.com"

  ALL_HOSTS=$(printf "%s\n%s" "$CORE_HOSTS" "$DERP_HOSTS" | sort -u)

  # Clear and repopulate table
  pfctl -t tailscale_hosts -T flush 2>/dev/null || true
  while read -r host; do
    [[ -n "$host" ]] && pfctl -t tailscale_hosts -T add "$host" 2>/dev/null || true
  done <<< "$ALL_HOSTS"

  echo "✓ Updated tailscale_hosts table with $(echo "$ALL_HOSTS" | wc -l | tr -d ' ') entries"
fi

# Show current table contents
echo ""
echo "Current tailscale_hosts table:"
pfctl -t tailscale_hosts -T show | head -n 20
TOTAL=$(pfctl -t tailscale_hosts -T show | wc -l | tr -d ' ')
if [[ $TOTAL -gt 20 ]]; then
  echo "... and $((TOTAL - 20)) more"
fi

logger -t offline-firewall "PF tables synced: $TOTAL Tailscale hosts"
