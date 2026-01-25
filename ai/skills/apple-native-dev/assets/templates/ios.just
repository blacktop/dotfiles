# iOS App Build Commands
# Usage: just ios::<recipe>

set positional-arguments := true

# Configuration - customize these
iphone_sim := "YOUR_SIMULATOR_UDID"
bundle_id := "com.example.myapp"
project := "Apps/MyApp/MyApp.xcodeproj"

# Default: list recipes
[private]
default:
    @just --list --justfile {{justfile()}}

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------

# Build for simulator
build:
    xcodebuild -project {{project}} -scheme MyApp \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
        -derivedDataPath .build/DerivedData build

# Generate Xcode project from project.yml
xcodegen:
    cd Apps/MyApp && xcodegen generate

# Open in Xcode
xcode:
    open {{project}}

# -----------------------------------------------------------------------------
# Simulator
# -----------------------------------------------------------------------------

# Boot simulator
boot:
    xcrun simctl boot {{iphone_sim}} 2>/dev/null || true
    open -a Simulator

# Install on simulator
install:
    xcrun simctl install {{iphone_sim}} \
        .build/DerivedData/Build/Products/Debug-iphonesimulator/MyApp.app

# Launch on simulator
launch:
    xcrun simctl launch {{iphone_sim}} {{bundle_id}}

# Build + install + launch
run: build install launch

# List simulators
list:
    xcrun simctl list devices available | grep -E "iPhone|iPad"

# -----------------------------------------------------------------------------
# Physical Device (iOS 17+)
# -----------------------------------------------------------------------------

# List connected devices
devices:
    xcrun devicectl list devices 2>/dev/null | head -10

# Build for device
device-build:
    @echo "Regenerating Xcode project..."
    cd Apps/MyApp && xcodegen generate
    @echo "Building for device..."
    xcodebuild -project {{project}} -scheme MyApp \
        -sdk iphoneos \
        -destination 'generic/platform=iOS' \
        -derivedDataPath .build/DerivedData \
        -allowProvisioningUpdates \
        build

# Install on connected device
device-install:
    #!/usr/bin/env bash
    set -e
    APP_PATH=".build/DerivedData/Build/Products/Debug-iphoneos/MyApp.app"
    if [ ! -d "$APP_PATH" ]; then
        echo "Error: App not found. Run 'just ios::device-build' first"
        exit 1
    fi
    DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep -m1 'iPhone' | awk '{print $NF}')
    if [ -z "$DEVICE_ID" ]; then
        echo "Error: No iPhone connected"
        exit 1
    fi
    echo "Installing to device: $DEVICE_ID"
    xcrun devicectl device install app --device "$DEVICE_ID" "$APP_PATH"

# Launch on connected device
device-launch:
    #!/usr/bin/env bash
    set -e
    DEVICE_ID=$(xcrun devicectl list devices 2>/dev/null | grep -m1 'iPhone' | awk '{print $NF}')
    if [ -z "$DEVICE_ID" ]; then
        echo "Error: No iPhone connected"
        exit 1
    fi
    xcrun devicectl device process launch --device "$DEVICE_ID" {{bundle_id}}

# Full device deploy
device-deploy: device-build device-install device-launch

# Release build
device-release:
    cd Apps/MyApp && xcodegen generate
    xcodebuild -project {{project}} -scheme MyApp \
        -sdk iphoneos \
        -destination 'generic/platform=iOS' \
        -derivedDataPath .build/DerivedData \
        -configuration Release \
        -allowProvisioningUpdates \
        build

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

# Setup credentials (auto-detect Team ID)
setup-credentials:
    #!/usr/bin/env bash
    set -e
    LOCAL_CONFIG="Apps/MyApp/Configs/Project.local.xcconfig"
    EXAMPLE_CONFIG="Apps/MyApp/Configs/Project.local.xcconfig.example"
    if [ -f "$LOCAL_CONFIG" ]; then
        echo "Config exists: $LOCAL_CONFIG"
        exit 0
    fi
    echo "Finding Team ID..."
    TEAM_ID=$(security find-certificate -c "Apple Development" -p 2>/dev/null | \
        openssl x509 -noout -subject 2>/dev/null | \
        grep -o 'OU=[^,]*' | cut -d= -f2 || echo "")
    if [ -z "$TEAM_ID" ]; then
        echo "Could not detect Team ID. Copy manually:"
        echo "  cp $EXAMPLE_CONFIG $LOCAL_CONFIG"
        exit 1
    fi
    echo "Found Team ID: $TEAM_ID"
    cp "$EXAMPLE_CONFIG" "$LOCAL_CONFIG"
    sed -i '' "s/YOUR_TEAM_ID_HERE/$TEAM_ID/" "$LOCAL_CONFIG"
    echo "Created: $LOCAL_CONFIG"

# Setup Zed LSP
setup-lsp:
    #!/usr/bin/env bash
    set -e
    if ! command -v xcode-build-server &> /dev/null; then
        echo "Installing xcode-build-server..."
        brew install xcode-build-server
    fi
    echo "Generating buildServer.json..."
    xcode-build-server config -project {{project}} -scheme MyApp
    echo "LSP setup complete!"
