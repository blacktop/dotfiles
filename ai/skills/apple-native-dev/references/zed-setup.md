# Zed Editor Setup for Apple Development

Configure Zed with full Swift LSP support for iOS/macOS projects using xcode-build-server.

## Prerequisites

```bash
# Install xcode-build-server
brew install xcode-build-server

# Verify installation
xcode-build-server --version
```

## Generate buildServer.json

The `buildServer.json` file bridges SourceKit-LSP to understand your Xcode project structure.

```bash
# From project root (after building at least once)
xcode-build-server config \
    -project Apps/MyApp/MyApp.xcodeproj \
    -scheme MyApp
```

This creates `buildServer.json` in the project root:
```json
{
  "name": "xcode build server",
  "version": "0.2",
  "bspVersion": "2.0",
  "languages": ["swift", "objective-c", "objective-cpp", "c", "cpp"],
  "argv": [
    "/opt/homebrew/bin/xcode-build-server"
  ],
  "workspace": "/path/to/project",
  "build_root": "/path/to/project",
  "indexStorePath": "..."
}
```

## Justfile Recipe

```just
setup-lsp:
    #!/usr/bin/env bash
    set -e
    if ! command -v xcode-build-server &> /dev/null; then
        echo "Installing xcode-build-server..."
        brew install xcode-build-server
    fi
    echo "Generating buildServer.json..."
    xcode-build-server config -project Apps/MyApp/MyApp.xcodeproj -scheme MyApp
    echo "LSP setup complete! Restart Zed."
```

## Zed Settings (Optional)

Zed auto-detects Swift via SourceKit-LSP. To customize:

```json
// ~/.config/zed/settings.json
{
  "languages": {
    "Swift": {
      "language_servers": ["sourcekit-lsp"],
      "format_on_save": "off"
    }
  }
}
```

## Workflow

1. **Build project first** (creates index):
   ```bash
   just ios::build
   # or: xcodebuild -project ... build
   ```

2. **Generate buildServer.json**:
   ```bash
   just ios::setup-lsp
   ```

3. **Open in Zed** - code completion works immediately

4. **After scheme/target changes**, regenerate:
   ```bash
   xcodegen generate && just ios::setup-lsp
   ```

## Gitignore

```gitignore
# Machine-specific LSP paths
buildServer.json
```

## Troubleshooting

**No code completion:**
- Build the project first to generate index
- Regenerate: `just ios::setup-lsp`
- Restart Zed

**Wrong project configuration:**
- Verify scheme: `xcodebuild -list -project Apps/MyApp/MyApp.xcodeproj`
- Regenerate with correct scheme

**SourceKit-LSP crashes:**
- Check Xcode version matches: `xcode-select -p`
- Update xcode-build-server: `brew upgrade xcode-build-server`

## Multiple Schemes

For projects with multiple schemes (iOS + Watch):
```bash
# Primary scheme for LSP
xcode-build-server config -project Apps/MyApp/MyApp.xcodeproj -scheme MyApp
```

LSP uses one scheme at a time. Switch schemes by regenerating.

## Comparison with Xcode

| Feature | Zed + xcode-build-server | Xcode |
|---------|--------------------------|-------|
| Code completion | Yes | Yes |
| Go to definition | Yes | Yes |
| Find references | Yes | Yes |
| Inline errors | Yes | Yes |
| Refactoring | Limited | Full |
| Build/Run | Via CLI | Integrated |
| Interface Builder | No | Yes |
