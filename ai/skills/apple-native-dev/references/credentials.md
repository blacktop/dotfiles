# Secure Credential Management (xcconfig)

Keep DEVELOPMENT_TEAM, signing identities, and other sensitive build settings out of git using xcconfig files.

## Directory Structure

```
Apps/MyApp/Configs/
├── Project.xcconfig           # Committed (loads local + defaults)
├── Project.local.xcconfig     # Gitignored (your Team ID)
└── Project.local.xcconfig.example  # Committed (template)
```

## File Contents

### Project.xcconfig (committed)
```xcconfig
// Base configuration - loads credentials from optional local file
#include? "Project.local.xcconfig"

// Development Team from local file or CI environment
DEVELOPMENT_TEAM = $(DEVELOPMENT_TEAM_OVERRIDE)

// Code signing defaults
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Development
PROVISIONING_PROFILE_SPECIFIER =
```

### Project.local.xcconfig.example (committed template)
```xcconfig
// Copy to Project.local.xcconfig and fill in your values
// DO NOT commit Project.local.xcconfig!
//
// Find your Team ID:
//   security find-certificate -c "Apple Development" -p | \
//     openssl x509 -noout -subject | grep -o 'OU=[^,]*'

DEVELOPMENT_TEAM_OVERRIDE = YOUR_TEAM_ID_HERE

// Optional: Override signing identity
// CODE_SIGN_IDENTITY = iPhone Developer: Your Name (XXXXXXXXXX)
```

### Project.local.xcconfig (gitignored, your file)
```xcconfig
DEVELOPMENT_TEAM_OVERRIDE = ABCD123456
```

## XcodeGen Integration

Add to `project.yml`:
```yaml
configFiles:
  Debug: Configs/Project.xcconfig
  Release: Configs/Project.xcconfig

settings:
  base:
    # Team ID comes from xcconfig, not here
```

## Gitignore Patterns

```gitignore
# xcconfig credentials
*.local.xcconfig
!*.local.xcconfig.example
```

## Auto-Detection Script

Justfile recipe to auto-detect Team ID from keychain:
```just
setup-credentials:
    #!/usr/bin/env bash
    set -e
    LOCAL_CONFIG="Apps/MyApp/Configs/Project.local.xcconfig"
    EXAMPLE_CONFIG="Apps/MyApp/Configs/Project.local.xcconfig.example"

    if [ -f "$LOCAL_CONFIG" ]; then
        echo "Local config exists: $LOCAL_CONFIG"
        exit 0
    fi

    echo "Finding Team ID..."
    TEAM_ID=$(security find-certificate -c "Apple Development" -p 2>/dev/null | \
        openssl x509 -noout -subject 2>/dev/null | \
        grep -o 'OU=[^,]*' | cut -d= -f2 || echo "")

    if [ -z "$TEAM_ID" ]; then
        echo "Could not auto-detect Team ID"
        echo "Copy and edit manually:"
        echo "  cp $EXAMPLE_CONFIG $LOCAL_CONFIG"
        exit 1
    fi

    echo "Found Team ID: $TEAM_ID"
    cp "$EXAMPLE_CONFIG" "$LOCAL_CONFIG"
    sed -i '' "s/YOUR_TEAM_ID_HERE/$TEAM_ID/" "$LOCAL_CONFIG"
    echo "Created: $LOCAL_CONFIG"
```

## CI/CD Environment Variables

For GitHub Actions, pass credentials via environment:
```yaml
env:
  DEVELOPMENT_TEAM: ${{ secrets.DEVELOPMENT_TEAM }}

- name: Build
  run: |
    xcodebuild ... DEVELOPMENT_TEAM=${{ env.DEVELOPMENT_TEAM }}
```

## Security Best Practices

| Pattern | Status | Purpose |
|---------|--------|---------|
| `*.local.xcconfig` | Gitignored | Personal Team ID |
| `*.p8` | Gitignored | APNs keys |
| `*.p12` | Gitignored | Signing certificates |
| `buildServer.json` | Gitignored | Machine-specific paths |
