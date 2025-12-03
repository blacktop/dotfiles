#!/usr/bin/env bash
# Test script to verify detection logic for offline-firewall.sh
# Safe to run - does NOT modify anything or require sudo

set -euo pipefail

echo "=== Offline Firewall Detection Test ==="
echo ""

# Test Tailscale CLI detection
echo "1. Tailscale CLI location:"
if command -v tailscale &>/dev/null; then
  echo "   ✓ Found in PATH: $(which tailscale)"
  TS_CMD="tailscale"
elif [[ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
  echo "   ✓ Found in Tailscale.app: /Applications/Tailscale.app/Contents/MacOS/Tailscale"
  TS_CMD="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
else
  echo "   ✗ NOT FOUND - tailscale CLI not available"
  TS_CMD=""
fi
echo ""

# Test TunName from tailscale CLI
echo "2. Tailscale TunName (from CLI JSON):"
if [[ -n "$TS_CMD" ]]; then
  TUN_NAME=$("$TS_CMD" status --json 2>/dev/null | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin)
    tun=data.get('Self',{}).get('TunName')
    if tun:
        print(tun)
except Exception:
    pass
" 2>/dev/null || true)
  if [[ -n "$TUN_NAME" ]]; then
    echo "   ✓ TunName: $TUN_NAME"
  else
    echo "   ✗ TunName not available (macOS system extension doesn't expose this)"
  fi
else
  TUN_NAME=""
  echo "   ✗ Skipped - no tailscale CLI"
fi
echo ""

# Test fallback: find utun with 100.x.x.x IP
echo "3. Tailscale interface (ifconfig fallback):"
TS_IF=$(ifconfig 2>/dev/null | awk '
  /^utun[0-9]+:/ { iface=$1; sub(/:$/, "", iface) }
  /inet 100\./ { print iface; exit }
')
if [[ -n "$TS_IF" ]]; then
  echo "   ✓ Detected: $TS_IF"
  # Show the interface details
  ifconfig "$TS_IF" 2>/dev/null | grep -E "flags|inet" | sed 's/^/     /'
else
  echo "   ✗ NOT FOUND - no utun interface with 100.x.x.x IP"
fi
echo ""

# Test Tailscale CIDR detection
echo "4. Tailscale CIDR (IP address):"
if [[ -n "$TS_CMD" ]]; then
  TS_CIDR=$("$TS_CMD" status --json 2>/dev/null | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin)
    addrs=data.get('Self',{}).get('TailscaleIPs') or data.get('Self',{}).get('Addresses') or []
    for a in addrs:
        if a.startswith('100.'):
            # Remove any existing CIDR suffix, then add /32
            ip = a.split('/')[0]
            print(f'{ip}/32')
            break
except Exception:
    pass
" 2>/dev/null || true)
  if [[ -n "$TS_CIDR" ]]; then
    echo "   ✓ Detected: $TS_CIDR"
  else
    echo "   ✗ Could not detect from tailscale CLI"
  fi
else
  TS_CIDR=""
  echo "   ✗ Skipped - no tailscale CLI"
fi

# Fallback from ifconfig
if [[ -z "$TS_CIDR" && -n "$TS_IF" ]]; then
  TS_CIDR=$(ifconfig "$TS_IF" 2>/dev/null | awk '/inet 100\./ { print $2"/32"; exit }')
  if [[ -n "$TS_CIDR" ]]; then
    echo "   ✓ Detected from ifconfig: $TS_CIDR"
  fi
fi
echo ""

# Test WAN interface detection
echo "5. WAN interface (default route):"
WAN_IF=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
if [[ -n "$WAN_IF" ]]; then
  echo "   ✓ Detected: $WAN_IF"
else
  echo "   ✗ NOT FOUND - no default route"
fi
echo ""

# Test LAN IP detection
echo "6. LAN IP (on WAN interface):"
if [[ -n "$WAN_IF" ]]; then
  LAN_IP=$(ifconfig "$WAN_IF" 2>/dev/null | awk '/inet / {print $2; exit}')
  if [[ -n "$LAN_IP" ]]; then
    echo "   ✓ Detected: $LAN_IP"
  else
    echo "   ✗ NOT FOUND - no IPv4 address on $WAN_IF"
  fi
else
  LAN_IP=""
  echo "   ✗ Skipped - no WAN interface"
fi
echo ""

# Summary
echo "=== Summary ==="
echo ""
if [[ -n "$TS_IF" && -n "$TS_CIDR" && -n "$WAN_IF" && -n "$LAN_IP" ]]; then
  echo "✓ All values detected successfully!"
  echo ""
  echo "You can run offline-firewall.sh without any flags, or explicitly:"
  echo ""
  echo "  ./offline-firewall.sh enable --ts-if $TS_IF --ts-cidr $TS_CIDR --wan-if $WAN_IF --lan-ip $LAN_IP"
  echo ""
else
  echo "✗ Some values could not be detected:"
  echo ""
  [[ -z "$TS_IF" ]] && echo "  --ts-if    (Tailscale interface not found)"
  [[ -z "$TS_CIDR" ]] && echo "  --ts-cidr  (Tailscale IP not found)"
  [[ -z "$WAN_IF" ]] && echo "  --wan-if   (WAN interface not found)"
  [[ -z "$LAN_IP" ]] && echo "  --lan-ip   (LAN IP not found)"
  echo ""
  echo "You'll need to pass these manually."
fi
