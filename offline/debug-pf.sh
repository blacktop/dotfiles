#!/usr/bin/env bash
# debug-pf.sh - Diagnostic script for troubleshooting PF and Tailscale issues
# Includes Network Extension and Apple firewall checks for macOS Tahoe 26.x
#
# Safe to run - collects information only, does not modify firewall state
#
# Usage: ./debug-pf.sh [--capture N]
#   --capture N   Also capture N seconds of packet traffic (requires sudo)

set -euo pipefail

CAPTURE_SECONDS=0
if [[ "${1:-}" == "--capture" ]]; then
  CAPTURE_SECONDS="${2:-10}"
fi

divider() {
  echo ""
  echo "═══════════════════════════════════════════════════════════════════════════════"
  echo "  $1"
  echo "═══════════════════════════════════════════════════════════════════════════════"
  echo ""
}

section() {
  echo ""
  echo "--- $1 ---"
}

warn() {
  echo "  ⚠️  $1"
}

# Collect basic info without sudo first
divider "PF & TAILSCALE DIAGNOSTIC REPORT"
echo "Timestamp: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "Hostname:  $(hostname)"
echo "macOS:     $(sw_vers -productVersion) ($(sw_vers -buildVersion))"

# Check if running on Tahoe
MACOS_VERSION=$(sw_vers -productVersion)
if [[ "$MACOS_VERSION" == 26.* ]]; then
  echo ""
  echo "  ⚠️  macOS Tahoe detected - Network Extension layer may affect traffic"
  echo "     before pf sees it. Check sections 7 and 8 below for NE/firewall state."
fi
echo ""

# ============================================================================
divider "1. NETWORK INTERFACE DETECTION"

section "Default route (WAN interface)"
route -n get default 2>/dev/null | grep -E "interface|gateway" || echo "  No default route found"

section "All network interfaces"
ifconfig -l 2>/dev/null || echo "  Failed to list interfaces"

section "Tailscale interface detection (utun with 100.x.x.x)"
TS_IF=$(ifconfig 2>/dev/null | awk '
  /^utun[0-9]+:/ { iface=$1; sub(/:$/, "", iface) }
  /inet 100\./ { print iface; exit }
')
if [[ -n "$TS_IF" ]]; then
  echo "  ✓ Tailscale interface: $TS_IF"
  ifconfig "$TS_IF" 2>/dev/null | grep -E "flags|inet|mtu" | sed 's/^/    /'
else
  echo "  ✗ No Tailscale interface found"
fi

section "All utun interfaces (for comparison)"
ifconfig 2>/dev/null | grep -E "^utun[0-9]+:" | while read -r line; do
  iface=$(echo "$line" | awk -F: '{print $1}')
  ip=$(ifconfig "$iface" 2>/dev/null | awk '/inet / {print $2}' | head -1)
  echo "  $iface: ${ip:-no IPv4}"
done

section "WAN interface details"
WAN_IF=$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')
if [[ -n "$WAN_IF" ]]; then
  echo "  WAN interface: $WAN_IF"
  ifconfig "$WAN_IF" 2>/dev/null | grep -E "flags|inet|ether|status" | sed 's/^/    /'
else
  echo "  ✗ No WAN interface detected"
fi

# ============================================================================
divider "2. TAILSCALE STATUS"

section "Tailscale CLI location"
if command -v tailscale &>/dev/null; then
  echo "  ✓ In PATH: $(which tailscale)"
  TS_CMD="tailscale"
elif [[ -x "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
  echo "  ✓ In Tailscale.app bundle"
  TS_CMD="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
else
  echo "  ✗ Tailscale CLI not found"
  TS_CMD=""
fi

if [[ -n "$TS_CMD" ]]; then
  section "Tailscale status"
  "$TS_CMD" status 2>&1 | head -20 || echo "  Failed to get status"

  section "Tailscale self info (from JSON)"
  "$TS_CMD" status --json 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    s = data.get("Self", {})
    print(f"  HostName:     {s.get(\"HostName\", \"N/A\")}")
    print(f"  DNSName:      {s.get(\"DNSName\", \"N/A\")}")
    print(f"  TailscaleIPs: {s.get(\"TailscaleIPs\", s.get(\"Addresses\", []))}")
    print(f"  TunName:      {s.get(\"TunName\", \"(not exposed on macOS)\")}")
    print(f"  Online:       {s.get(\"Online\", \"N/A\")}")
    print(f"  Relay:        {s.get(\"Relay\", \"N/A\")}")
except Exception as e:
    print(f"  Error parsing JSON: {e}")
' 2>/dev/null || echo "  Failed to parse Tailscale JSON"
fi

# ============================================================================
divider "3. PF FIREWALL STATUS"

section "PF enabled status"
PF_ENABLED=false
if sudo pfctl -s info 2>/dev/null | grep -q "Status: Enabled"; then
  echo "  ✓ PF is ENABLED"
  PF_ENABLED=true
else
  echo "  ✗ PF is DISABLED"
fi

section "PF info summary"
sudo pfctl -s info 2>/dev/null | head -20 || echo "  Failed to get PF info (need sudo?)"

section "PF memory/state limits"
sudo pfctl -s memory 2>/dev/null | head -10 || echo "  Failed to get memory info"

section "PF 'set skip' interfaces"
echo "  Interfaces that bypass pf filtering:"
sudo pfctl -s info 2>/dev/null | grep -i "skip" || echo "  (none configured)"
# Also check from running rules
SKIP_IFS=$(sudo pfctl -sr 2>/dev/null | grep "set skip on" | sed 's/set skip on /  /')
if [[ -n "$SKIP_IFS" ]]; then
  echo "$SKIP_IFS"
else
  sudo pfctl -sa 2>/dev/null | grep -i "skip" | sed 's/^/  /' || true
fi

section "Current PF rules (main ruleset)"
echo "  (First 50 rules)"
sudo pfctl -sr 2>/dev/null | head -50 || echo "  Failed to get rules"

section "PF anchors"
sudo pfctl -s Anchors 2>/dev/null || echo "  No anchors or failed to list"

section "Offline-updates anchor rules"
if sudo pfctl -a offline-updates -sr 2>/dev/null | grep -q .; then
  echo "  ✓ Update window is OPEN"
  sudo pfctl -a offline-updates -sr 2>/dev/null
else
  echo "  ✗ Update window is CLOSED (no rules in anchor)"
fi

section "Apple anchors (com.apple)"
APPLE_ANCHORS=$(sudo pfctl -s Anchors 2>/dev/null | grep "com.apple" || true)
if [[ -n "$APPLE_ANCHORS" ]]; then
  echo "$APPLE_ANCHORS" | while read -r anchor; do
    echo "  Anchor: $anchor"
    sudo pfctl -a "$anchor" -sr 2>/dev/null | head -5 | sed 's/^/    /'
  done
else
  echo "  (no com.apple anchors loaded)"
fi

# ============================================================================
divider "4. PF TABLES"

section "All PF tables"
sudo pfctl -s Tables 2>/dev/null || echo "  No tables defined"

for table in tailscale_hosts lmstudio_hosts update_hosts package_repos; do
  section "Table: $table"
  count=$(sudo pfctl -t "$table" -T show 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -gt 0 ]]; then
    echo "  Entries: $count"
    sudo pfctl -t "$table" -T show 2>/dev/null | head -10 | sed 's/^/    /'
    [[ "$count" -gt 10 ]] && echo "    ... (truncated)"
  else
    echo "  (empty or not loaded)"
  fi
done

# ============================================================================
divider "5. PF STATES"

section "Active PF states (first 30)"
sudo pfctl -s states 2>/dev/null | head -30 || echo "  No states or failed"

section "State count by interface"
sudo pfctl -s states 2>/dev/null | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# ============================================================================
divider "6. CONFIG FILES"

section "/etc/pf.offline.vars"
if [[ -f /etc/pf.offline.vars ]]; then
  cat /etc/pf.offline.vars
else
  echo "  (not installed)"
fi

section "/etc/pf.offline.conf (first 40 lines)"
if [[ -f /etc/pf.offline.conf ]]; then
  head -40 /etc/pf.offline.conf
else
  echo "  (not installed)"
fi

section "Config syntax validation"
if [[ -f /etc/pf.offline.conf ]]; then
  if sudo pfctl -nf /etc/pf.offline.conf 2>&1; then
    echo "  ✓ Syntax OK"
  else
    echo "  ✗ Syntax errors detected"
  fi
else
  echo "  (no config to validate)"
fi

# ============================================================================
divider "7. MACOS APPLICATION FIREWALL (socketfilterfw)"

section "Application Firewall status"
# This is the GUI firewall in System Settings > Network > Firewall
APP_FW_STATUS=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")
echo "  Global state: $APP_FW_STATUS"

if echo "$APP_FW_STATUS" | grep -qi "enabled"; then
  warn "Application Firewall is ENABLED - this can block traffic independently of pf!"
  echo ""
  echo "  Firewall settings:"
  /usr/libexec/ApplicationFirewall/socketfilterfw --getblockall 2>/dev/null | sed 's/^/    /' || true
  /usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>/dev/null | sed 's/^/    /' || true
  /usr/libexec/ApplicationFirewall/socketfilterfw --getallowsigned 2>/dev/null | sed 's/^/    /' || true
  /usr/libexec/ApplicationFirewall/socketfilterfw --getallowsignedapp 2>/dev/null | sed 's/^/    /' || true

  section "Application Firewall app list (first 20)"
  /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | head -40 | sed 's/^/  /'

  # Check if Tailscale is allowed
  section "Tailscale in Application Firewall"
  if /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | grep -qi tailscale; then
    /usr/libexec/ApplicationFirewall/socketfilterfw --listapps 2>/dev/null | grep -i tailscale | sed 's/^/  /'
  else
    warn "Tailscale not found in Application Firewall app list"
    echo "     If blocking occurs, try: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Tailscale.app"
  fi
else
  echo "  ✓ Application Firewall is disabled (good - won't interfere with pf)"
fi

# ============================================================================
divider "8. NETWORK EXTENSIONS & CONTENT FILTERS (Tahoe 26.x)"

section "System Extensions (Network Extensions)"
echo "  Looking for network-related system extensions..."
systemextensionsctl list 2>/dev/null | grep -iE "network|filter|vpn|tailscale|firewall" | sed 's/^/  /' || echo "  (none found or command failed)"

section "All active System Extensions"
systemextensionsctl list 2>/dev/null | sed 's/^/  /' || echo "  (systemextensionsctl not available)"

section "Network Extension configurations (neutil)"
# Check for active NE configurations
if command -v neutil &>/dev/null; then
  echo "  Active Network Extension providers:"
  sudo neutil session status 2>/dev/null | head -30 | sed 's/^/    /' || echo "    (no active sessions or permission denied)"
else
  echo "  neutil not available"
fi

section "DNS Configuration"
echo "  Checking for DNS filters or overrides..."
scutil --dns 2>/dev/null | grep -E "nameserver|resolver|search" | head -20 | sed 's/^/  /'

section "Content Filter / VPN Profiles"
echo "  Checking for installed configuration profiles..."
PROFILES=$(sudo profiles list 2>/dev/null || true)
if [[ -n "$PROFILES" ]]; then
  echo "$PROFILES" | grep -iE "filter|vpn|network|firewall|content" | sed 's/^/  /' || echo "  (no network-related profiles found)"
  echo ""
  echo "  All profiles:"
  echo "$PROFILES" | sed 's/^/    /'
else
  echo "  (no profiles installed or profiles command failed)"
fi

section "Network Extension entitlements check"
# On Tahoe, NE can intercept traffic before pf
echo "  Tailscale Network Extension status:"
if [[ -d "/Applications/Tailscale.app" ]]; then
  # Check if Tailscale's system extension is loaded
  if systemextensionsctl list 2>/dev/null | grep -qi tailscale; then
    echo "  ✓ Tailscale system extension is loaded"
    systemextensionsctl list 2>/dev/null | grep -i tailscale | sed 's/^/    /'
  else
    echo "  ⚠️  Tailscale system extension not found in list"
    echo "     This might indicate Tailscale is using userspace networking"
  fi
fi

# ============================================================================
divider "9. CONNECTIVITY TESTS"

section "Tailscale ping to controlplane.tailscale.com"
if ping -c 2 -t 3 controlplane.tailscale.com &>/dev/null; then
  echo "  ✓ Reachable"
else
  echo "  ✗ Not reachable"
fi

section "DNS resolution test"
for host in controlplane.tailscale.com github.com; do
  if dig +short "$host" A 2>/dev/null | head -1 | grep -qE '^[0-9]+\.'; then
    echo "  ✓ $host resolves to $(dig +short "$host" A 2>/dev/null | head -1)"
  else
    echo "  ✗ $host failed to resolve"
  fi
done

if [[ -n "$TS_IF" ]]; then
  section "Ping via Tailscale interface"
  # Get our Tailscale IP
  TS_IP=$(ifconfig "$TS_IF" 2>/dev/null | awk '/inet 100\./ {print $2; exit}')
  if [[ -n "$TS_IP" ]]; then
    echo "  Local Tailscale IP: $TS_IP"
    # Try pinging localhost via Tailscale
    if ping -c 2 -t 3 "$TS_IP" &>/dev/null; then
      echo "  ✓ Can ping self via Tailscale IP"
    else
      echo "  ✗ Cannot ping self via Tailscale IP"
    fi
  fi

  section "Tailscale peer connectivity test"
  if [[ -n "$TS_CMD" ]]; then
    # Get first peer and try to ping
    PEER=$("$TS_CMD" status 2>/dev/null | grep -v "^#" | awk 'NR==2 {print $1}')
    if [[ -n "$PEER" ]]; then
      echo "  Testing connectivity to peer: $PEER"
      if "$TS_CMD" ping --c 2 --timeout 3s "$PEER" &>/dev/null; then
        echo "  ✓ Can reach peer via Tailscale"
      else
        echo "  ✗ Cannot reach peer via Tailscale"
      fi
    else
      echo "  (no peers found to test)"
    fi
  fi
fi

# ============================================================================
divider "10. SYSTEM LOGS (recent entries)"

section "Recent offline-firewall log entries"
log show --predicate 'eventMessage CONTAINS "offline-firewall"' --last 5m 2>/dev/null | tail -20 || echo "  No entries found"

section "Recent PF-related kernel messages"
log show --predicate 'subsystem == "com.apple.pf" OR eventMessage CONTAINS "pf:"' --last 5m 2>/dev/null | tail -20 || echo "  No entries found"

section "Recent Network Extension messages"
log show --predicate 'subsystem CONTAINS "networkextension" OR subsystem CONTAINS "NEFilterDataProvider"' --last 5m 2>/dev/null | tail -15 || echo "  No entries found"

section "Recent Tailscale messages"
log show --predicate 'process CONTAINS "Tailscale" OR subsystem CONTAINS "tailscale"' --last 5m 2>/dev/null | tail -15 || echo "  No entries found"

# ============================================================================
if [[ "$CAPTURE_SECONDS" -gt 0 ]]; then
  divider "11. PACKET CAPTURE ($CAPTURE_SECONDS seconds)"

  section "Checking for pflog0 interface"
  if ifconfig pflog0 &>/dev/null; then
    echo "  ✓ pflog0 exists"
  else
    echo "  ✗ pflog0 does not exist (PF logging may not be enabled)"
    echo "  Falling back to interface captures"
  fi

  CAPTURE_DIR="/tmp/pf-debug-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$CAPTURE_DIR"
  echo ""
  echo "  Capturing for $CAPTURE_SECONDS seconds to $CAPTURE_DIR/"
  echo "  Press Ctrl+C to stop early..."
  echo ""

  # Start captures in background
  if [[ -n "$TS_IF" ]]; then
    sudo tcpdump -i "$TS_IF" -c 1000 -w "$CAPTURE_DIR/tailscale-$TS_IF.pcap" 2>/dev/null &
    TCPDUMP_TS=$!
    echo "  Started capture on $TS_IF (PID $TCPDUMP_TS)"
  fi

  if [[ -n "$WAN_IF" ]]; then
    sudo tcpdump -i "$WAN_IF" -c 1000 -w "$CAPTURE_DIR/wan-$WAN_IF.pcap" 2>/dev/null &
    TCPDUMP_WAN=$!
    echo "  Started capture on $WAN_IF (PID $TCPDUMP_WAN)"
  fi

  if ifconfig pflog0 &>/dev/null; then
    sudo tcpdump -i pflog0 -c 500 -w "$CAPTURE_DIR/pflog.pcap" 2>/dev/null &
    TCPDUMP_PF=$!
    echo "  Started capture on pflog0 (PID $TCPDUMP_PF)"
  fi

  # Wait for capture duration
  sleep "$CAPTURE_SECONDS"

  # Stop captures
  sudo kill "$TCPDUMP_TS" 2>/dev/null || true
  sudo kill "$TCPDUMP_WAN" 2>/dev/null || true
  sudo kill "$TCPDUMP_PF" 2>/dev/null || true

  echo ""
  echo "  Captures complete. Files in $CAPTURE_DIR/:"
  ls -la "$CAPTURE_DIR/"
  echo ""
  echo "  View with: tcpdump -r $CAPTURE_DIR/<file>.pcap"
fi

# ============================================================================
divider "DIAGNOSTIC SUMMARY"

echo "Key findings:"
echo ""

# Summarize findings
if [[ -n "$TS_IF" ]]; then
  echo "  ✓ Tailscale interface: $TS_IF"
else
  echo "  ✗ Tailscale interface: NOT DETECTED"
fi

if [[ -n "$WAN_IF" ]]; then
  echo "  ✓ WAN interface: $WAN_IF"
else
  echo "  ✗ WAN interface: NOT DETECTED"
fi

if [[ "$PF_ENABLED" == "true" ]]; then
  echo "  ✓ PF: ENABLED"
else
  echo "  ○ PF: DISABLED"
fi

if sudo pfctl -a offline-updates -sr 2>/dev/null | grep -q .; then
  echo "  ○ Update window: OPEN"
else
  echo "  ✓ Update window: CLOSED"
fi

ts_count=$(sudo pfctl -t tailscale_hosts -T show 2>/dev/null | wc -l | tr -d ' ')
echo "  ○ tailscale_hosts table: $ts_count entries"

# Check for potential issues
echo ""
echo "Potential issues detected:"
echo ""

ISSUES_FOUND=false

# Check Application Firewall
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -qi "enabled"; then
  echo "  ⚠️  Application Firewall is ENABLED"
  echo "     This can block traffic before pf sees it!"
  echo "     Disable with: sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
  echo ""
  ISSUES_FOUND=true
fi

# Check for content filters
if sudo profiles list 2>/dev/null | grep -qiE "filter|content"; then
  echo "  ⚠️  Content filter profiles detected"
  echo "     These can intercept/block traffic independently of pf"
  echo ""
  ISSUES_FOUND=true
fi

# Check if set skip is configured for Tailscale interface
if [[ -n "$TS_IF" ]]; then
  if ! sudo pfctl -sr 2>/dev/null | grep -q "set skip on.*$TS_IF"; then
    # Also check via pfctl -s info
    if ! sudo pfctl -s info 2>/dev/null | grep -qi "skip.*$TS_IF"; then
      echo "  ⚠️  'set skip on $TS_IF' not found in active rules"
      echo "     Tailscale interface may be filtered by pf rules"
      echo ""
      ISSUES_FOUND=true
    fi
  fi
fi

# Check Tahoe-specific issues
if [[ "$MACOS_VERSION" == 26.* ]]; then
  echo "  ℹ️  macOS Tahoe 26.x detected"
  echo "     Network Extension layer may intercept traffic before pf"
  echo "     If traffic is blocked despite correct pf rules, check:"
  echo "       - System Settings > Network > Firewall (disable or allow Tailscale)"
  echo "       - System Settings > Privacy & Security > Network Extensions"
  echo "       - Any installed VPN or content filter profiles"
  echo ""
  ISSUES_FOUND=true
fi

if [[ "$ISSUES_FOUND" == "false" ]]; then
  echo "  ✓ No obvious issues detected"
fi

echo ""
echo "Quick fixes to try if traffic is blocked:"
echo "  1. Disable Application Firewall:"
echo "     sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off"
echo ""
echo "  2. Disable PF temporarily:"
echo "     sudo pfctl -d"
echo ""
echo "  3. Reload PF config:"
echo "     sudo pfctl -f /etc/pf.offline.conf"
echo ""
echo "  4. Sync Tailscale tables:"
echo "     sudo ./sync-pf-tables.sh"
echo ""
echo "  5. Check if Tailscale needs re-authentication:"
echo "     tailscale status"
echo "     tailscale up"
echo ""
