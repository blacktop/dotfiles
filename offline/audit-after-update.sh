#!/usr/bin/env bash
# Post-update security audit for offline macOS research system
set -euo pipefail

echo "=== Post-Update Security Audit ==="
echo "Timestamp: $(date)"
echo ""

# Check if update window is still open
echo "=== Update Window Status ==="
if sudo pfctl -a offline-updates -sr 2>/dev/null | grep -q .; then
  echo "⚠️  WARNING: Update window is still OPEN"
  echo "   Close with: sudo ~/Developer/Mine/blacktop/dotfiles/offline/offline-firewall.sh close-updates"
else
  echo "✓ Update window is CLOSED"
fi
echo ""

# Check active network connections
echo "=== Active Network Connections ==="
ESTABLISHED=$(netstat -an | grep ESTABLISHED | grep -v "127.0.0.1\|::1" | wc -l | tr -d ' ')
if [[ $ESTABLISHED -gt 0 ]]; then
  echo "⚠️  Found $ESTABLISHED active connections:"
  netstat -an | grep ESTABLISHED | grep -v "127.0.0.1\|::1" | head -20
  if [[ $ESTABLISHED -gt 20 ]]; then
    echo "... and $((ESTABLISHED - 20)) more"
  fi
else
  echo "✓ No active external connections"
fi
echo ""

# Check listening services
echo "=== Listening Services ==="
LISTENING=$(lsof -i -P | grep LISTEN | grep -v "127.0.0.1\|localhost" | wc -l | tr -d ' ')
if [[ $LISTENING -gt 0 ]]; then
  echo "Found $LISTENING listening services:"
  lsof -i -P | grep LISTEN | grep -v "127.0.0.1\|localhost"
else
  echo "✓ No listening services on external interfaces"
fi
echo ""

# Check Tailscale status
echo "=== Tailscale Status ==="
if command -v tailscale &>/dev/null; then
  if tailscale status --json &>/dev/null; then
    TS_ONLINE=$(tailscale status --json | python3 -c 'import json,sys; print(json.load(sys.stdin)["BackendState"])' 2>/dev/null || echo "unknown")
    echo "Tailscale state: $TS_ONLINE"

    if [[ "$TS_ONLINE" == "Running" ]]; then
      echo "✓ Tailscale is running"
      TS_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
      echo "  Tailscale IP: $TS_IP"
    else
      echo "⚠️  Tailscale is not running properly"
    fi
  else
    echo "⚠️  Tailscale is not authenticated"
  fi
else
  echo "✗ Tailscale not installed"
fi
echo ""

# Check PF status
echo "=== PF Firewall Status ==="
PF_STATUS=$(sudo pfctl -s info 2>/dev/null | head -5)
if echo "$PF_STATUS" | grep -q "Status: Enabled"; then
  echo "✓ PF is enabled"
  echo "$PF_STATUS"
else
  echo "✗ PF is NOT enabled - CRITICAL SECURITY ISSUE"
  echo "  Enable with: sudo pfctl -e -f /etc/pf.offline.conf"
fi
echo ""

# Check recent firewall blocks (if pflog is enabled)
echo "=== Recent Firewall Activity (last 50 blocks) ==="
if sudo pfctl -ss 2>/dev/null | head -50 | grep -q .; then
  sudo pfctl -ss | head -50
else
  echo "(No recent state information available)"
fi
echo ""

# System services check
echo "=== Potentially Risky Services ==="
SERVICES=("com.apple.screensharing" "com.apple.remotedesktop" "com.apple.ftp-proxy")
for svc in "${SERVICES[@]}"; do
  if launchctl list | grep -q "$svc"; then
    echo "⚠️  $svc is loaded"
  fi
done
echo "✓ Audit complete"

# Log audit
logger -t offline-firewall "Security audit completed: $ESTABLISHED active connections, PF $(echo "$PF_STATUS" | grep Status | awk '{print $2}')"
