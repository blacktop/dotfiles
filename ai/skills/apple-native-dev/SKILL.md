---
name: apple-native-dev
description: |
  Build, test, preview, sign, and deploy iOS/macOS apps using CLI tools, Zed, or Xcode's MCP server.
  Use for XcodeGen project setup, xcconfig signing settings, Swift LSP setup, headless Xcode 27+
  workflows, simulator UI verification, physical-device deployment, CI, and build troubleshooting.
---

# Apple Native Development

Use the repository's existing project format, build commands, and selected Xcode.
Keep XcodeGen as the source of truth when the project is generated; use Xcode's
project tools when the project is maintained directly.

For Xcode MCP setup, Apple-provided skills, native project templates, SwiftUI
preview inspection, or simulator interaction, read
[references/xcode-mcp.md](references/xcode-mcp.md). The CLI workflow below remains
useful for reproducible builds, CI, Zed, and physical devices.

## CLI and XcodeGen Workflow

### 1. Project Setup
```bash
# Install tools
brew install xcodegen just xcode-build-server

# Generate Xcode project from project.yml
cd Apps/MyApp && xcodegen generate
```

### 2. Credential Management
Use xcconfig files to keep Team ID out of git. See [references/credentials.md](references/credentials.md).

```
Apps/MyApp/Configs/
├── Project.xcconfig           # Committed (loads local + defaults)
├── Project.local.xcconfig     # Gitignored (your Team ID)
└── Project.local.xcconfig.example  # Committed template
```

**Quick setup** (auto-detects Team ID from keychain):
```bash
just ios::setup-credentials
```

### 3. Zed Editor LSP
Generate `buildServer.json` for code completion. See [references/zed-setup.md](references/zed-setup.md).

```bash
just ios::setup-lsp
# Or manually:
xcode-build-server config -project Apps/MyApp/MyApp.xcodeproj -scheme MyApp
```

### 4. Build & Deploy

**Simulator:**
```bash
just ios::build      # Build for simulator
just ios::run        # Build + install + launch
```

**Physical Device (iOS 17+):**
```bash
just ios::device-deploy  # Build + install + launch on iPhone
```

See [references/justfile.md](references/justfile.md) for all commands.

### 5. CI/CD
GitHub Actions scaffold at `.github/workflows/ios-build.yml.disabled`. See [references/ci-cd.md](references/ci-cd.md).

## Key Files

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen project definition |
| `Configs/Project.xcconfig` | Base build settings (committed) |
| `Configs/Project.local.xcconfig` | Credentials (gitignored) |
| `buildServer.json` | LSP configuration (gitignored) |
| `justfile` or `ios.just` | Build commands |

## Gitignore Patterns
```gitignore
# Credentials
*.local.xcconfig
!*.local.xcconfig.example

# Editor integration
buildServer.json

# Only ignore project bundles when XcodeGen is the source of truth.
# Keep directly maintained Xcode projects in version control.
*.xcodeproj/
```

## Templates

Copy from `assets/templates/` when bootstrapping:
- `Project.xcconfig` - Base xcconfig (committed)
- `Project.local.xcconfig.example` - Credential template (committed)
- `project.yml` - XcodeGen project definition
- `ios.just` - Justfile module for iOS commands
- `ios-build.yml.disabled` - GitHub Actions scaffold

## Troubleshooting

**"Unable to find module dependency" in CLI builds:**
Disable hardened runtime during development:
```yaml
# project.yml
settings:
  base:
    ENABLE_HARDENED_RUNTIME: NO
    ENABLE_ENHANCED_SECURITY: NO
```

**No code completion in Zed:**
Regenerate after building: `just ios::setup-lsp`

**Device install fails:**
Ensure device is trusted and connected: `just ios::devices`
