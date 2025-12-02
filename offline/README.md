# Offline Profile (macOS PF + Tailscale)

Secure offline research system with Tailscale-only access and controlled update windows.

## What It Does

- **Base profile**: Tailscale tunnel only; all WAN/LAN egress blocked
- **Update window**: Temporarily allow HTTPS to approved domains (GitHub, Homebrew, LM Studio, Hugging Face, package registries)
- **Security**: Default-deny firewall with explicit allowlists
- **Audit**: Post-update security verification

## Files

- `offline-firewall.sh` — Main management script
- `pf.offline.conf` — Base firewall ruleset (Tailscale-only)
- `pf.offline-updates.conf` — Temporary allowlist for update windows
- `sync-pf-tables.sh` — Refresh Tailscale DERP endpoint tables
- `audit-after-update.sh` — Post-update security audit
- `com.offline.pf.plist` — Launch daemon for PF persistence on boot

## Fish Functions

- `offline-updates [seconds]` — Open update window (default 900s/15min)
- `offline-updates-close` — Close update window immediately
- `offline-updates-status` — Check if window is open

## Installation

### 1. Enable Offline Profile

```bash
sudo ./offline/offline-firewall.sh enable
```

This will:
- Auto-detect Tailscale interface, WAN interface, and Tailscale IP
- Install PF rules to `/etc/pf.offline.conf`
- Enable packet filtering
- Display configuration summary

**Override auto-detection if needed:**
```bash
sudo ./offline/offline-firewall.sh --ts-if utun3 --wan-if en0 --ts-cidr 100.80.10.5/32 enable
```

### 2. Enable PF Persistence (Recommended)

PF must be re-enabled after each reboot. Install the launch daemon for automatic startup:

```bash
sudo cp offline/com.offline.pf.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.offline.pf.plist
```

Verify it loads on boot:
```bash
sudo launchctl list | grep offline
```

### 3. Sync Tailscale Tables (Optional)

Fetch current Tailscale DERP endpoints:
```bash
sudo ./offline/offline-firewall.sh sync-tables
```

## Usage

### Opening Update Windows

#### From Fish Shell
```fish
# 15-minute window (default)
offline-updates

# 30-minute window
offline-updates 1800

# Check status
offline-updates-status

# Close early
offline-updates-close
```

#### From Bash
```bash
# 15-minute window
sudo ./offline/offline-firewall.sh open-updates 900

# Close immediately
sudo ./offline/offline-firewall.sh close-updates
```

### Monitoring

#### Check Firewall Status
```bash
sudo ./offline/offline-firewall.sh status
```

Shows:
- PF enabled/disabled
- Active rules
- Update window state
- Table contents

#### Run Security Audit
```bash
sudo ./offline/offline-firewall.sh audit
```

Checks:
- Update window state
- Active network connections
- Listening services
- Tailscale status
- PF enabled status
- Recent firewall blocks

### View System Logs

All operations are logged to system log:
```bash
# View offline-firewall logs
log show --predicate 'subsystem == "offline-firewall"' --last 1h

# View offline-updates logs  
log show --predicate 'subsystem == "offline-updates"' --last 1h

# PF startup logs
tail -f /var/log/offline-pf.log
```

## Allowed Domains During Update Windows

### Package Registries
- **Python**: pypi.org, files.pythonhosted.org
- **Rust**: crates.io, static.crates.io, index.crates.io
- **Go**: golang.org, proxy.golang.org, pkg.go.dev, sum.golang.org
- **Node**: registry.npmjs.org, registry.yarnpkg.com
- **General**: dl.google.com

### Update Sources
- **GitHub**: github.com, api.github.com, raw.githubusercontent.com, objects.githubusercontent.com, ghcr.io
- **Homebrew**: formulae.brew.sh, homebrew.bintray.com

### AI Models
- **LM Studio**: lmstudio.ai
- **Hugging Face**: huggingface.co, hf.co, cdn-lfs.huggingface.co, cdn-lfs-us-1.hf.co, cdn-lfs-eu-1.hf.co, cas-bridge.xethub.hf.co, transfer.xethub.hf.co, cas-server.xethub.hf.co
- **CDN**: cloudfront.net

## Security Model

### Base Profile (Always Active)
```
1. Block all inbound traffic
2. Block all outbound traffic
3. Allow Tailscale tunnel (utun interface) - full bidirectional
4. Allow minimal Tailscale control plane:
   - UDP 3478, 41641 (DERP/STUN)
   - TCP 443 to Tailscale control hosts
```

### Update Window (Temporary)
```
1. Base profile remains active
2. Add HTTPS (TCP 443) to approved domain lists
3. Auto-closes after specified duration
4. Logs all open/close events
```

## macOS 26 Tahoe Compatibility

✓ Fully compatible with macOS 26.x Tahoe
- PF (Packet Filter) is unchanged in macOS 26
- All pfctl commands work as expected
- Logging via `logger` compensates for removed Console.app firewall log

## Troubleshooting

### PF Not Starting on Boot
```bash
# Check launch daemon
sudo launchctl list | grep offline

# Load manually
sudo launchctl load /Library/LaunchDaemons/com.offline.pf.plist

# Check logs
tail /var/log/offline-pf.log
```

### Cannot Reach Tailscale Control Plane
```bash
# Sync DERP endpoints
sudo ./offline/offline-firewall.sh sync-tables

# Verify Tailscale status
tailscale status

# Check PF tables
sudo pfctl -t tailscale_hosts -T show
```

### Update Window Not Working
```bash
# Verify syntax
sudo pfctl -nf /etc/pf.offline-updates.conf

# Check window status
offline-updates-status

# View active rules
sudo pfctl -a offline-updates -sr
```

### Network Completely Blocked
```bash
# Temporarily disable PF to troubleshoot
sudo pfctl -d

# Re-enable with base config
sudo pfctl -e -f /etc/pf.offline.conf

# Check interface names match
grep -E "ts_if|wan_if" /etc/pf.offline.vars
```

## Best Practices

1. **Minimize Update Windows**: Keep windows short (15-30 minutes)
2. **Audit After Updates**: Run `audit-after-update.sh` after closing windows
3. **Monitor Logs**: Check system logs regularly for anomalies
4. **Sync Tables Weekly**: Update Tailscale DERP endpoints periodically
5. **Verify PF on Boot**: Ensure launch daemon loads successfully
6. **Review Connections**: Use `netstat` to verify no persistent connections remain

## Advanced: Enable PF Logging (Optional)

For packet-level visibility on macOS 26 (where Console.app firewall log was removed):

### 1. Add Logging to pf.offline.conf

Edit `/etc/pf.offline.conf` and add after `set skip on lo0`:
```pf
# Enable packet logging
set loginterface $wan_if

# Optional: log blocked packets (verbose)
# block log all
```

### 2. Monitor pflog Interface

```bash
# View real-time blocks
sudo tcpdump -n -e -ttt -i pflog0

# Filter by interface
sudo tcpdump -n -e -ttt -i pflog0 -i en0

# Save to file
sudo tcpdump -n -e -ttt -i pflog0 -w /tmp/pflog.pcap
```

## Architecture

```
┌─────────────────────────────────────────────┐
│           Internet / WAN / LAN              │
│                  ▲                          │
│                  │ BLOCKED                  │
└──────────────────┼──────────────────────────┘
                   │
                   │ PF Rules (pf.offline.conf)
                   │
┌──────────────────┼──────────────────────────┐
│                  │                          │
│  ┌───────────────┴──────────────┐          │
│  │  Tailscale Control Plane     │          │
│  │  - UDP 3478, 41641           │          │
│  │  - TCP 443 (control hosts)   │          │
│  └──────────────────────────────┘          │
│                                             │
│  ┌──────────────────────────────┐          │
│  │  Tailscale Tunnel (utun)     │◄─────────┼─── Full Access
│  │  - All traffic allowed       │          │
│  └──────────────────────────────┘          │
│                                             │
│  ┌──────────────────────────────┐          │
│  │  Update Window (Anchor)      │          │
│  │  - Temporary HTTPS rules     │          │
│  │  - Auto-expires              │          │
│  └──────────────────────────────┘          │
│                                             │
│              macOS System                   │
└─────────────────────────────────────────────┘
```

## References

- [macOS PF Configuration](https://iyanmv.medium.com/setting-up-correctly-packet-filter-pf-firewall-on-any-macos-from-sierra-to-big-sur-47e70e062a0e)
- [PF Quick Start Guide](https://blog.neilsabol.site/post/quickly-easily-adding-pf-packet-filter-firewall-rules-macos-osx/)
- [Tailscale Security Model](https://www.xda-developers.com/is-tailscale-the-safest-way-to-access-your-home-network-remotely/)
- [Air-Gapped Systems Best Practices](https://www.imperva.com/learn/data-security/air-gapping/)
