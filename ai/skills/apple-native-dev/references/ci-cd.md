# CI/CD for Apple Apps (GitHub Actions)

GitHub Actions workflows for iOS/macOS apps.

## Scaffold Workflow

Create `.github/workflows/ios-build.yml.disabled` (rename to enable):

```yaml
name: iOS Build

on:
  push:
    branches: [main]
    paths:
      - 'Sources/**'
      - 'Apps/**'
      - 'Package.swift'
  pull_request:
    branches: [main]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

env:
  DEVELOPER_DIR: /Applications/Xcode.app/Contents/Developer
  DERIVED_DATA: .build/DerivedData

jobs:
  build:
    name: Build iOS App
    runs-on: macos-14
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode Project
        run: cd Apps/MyApp && xcodegen generate

      # Unsigned simulator build (no secrets required)
      - name: Build for Simulator
        run: |
          xcodebuild -project Apps/MyApp/MyApp.xcodeproj \
            -scheme MyApp \
            -sdk iphonesimulator \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -derivedDataPath ${{ env.DERIVED_DATA }} \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            build

      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: MyApp-Simulator
          path: ${{ env.DERIVED_DATA }}/Build/Products/Debug-iphonesimulator/MyApp.app
          retention-days: 7

  test:
    name: Run Tests
    runs-on: macos-14
    timeout-minutes: 20

    steps:
      - uses: actions/checkout@v4

      - name: Run Swift Tests
        run: swift test
```

## Signed Device Builds

Requires GitHub Secrets:
- `DEVELOPMENT_TEAM` - Apple Team ID (10 chars)
- `CERTIFICATES_P12_B64` - Base64-encoded .p12 certificate
- `CERTIFICATES_P12_PASS` - Password for .p12

```yaml
- name: Import Certificates
  uses: apple-actions/import-codesign-certs@v2
  with:
    p12-file-base64: ${{ secrets.CERTIFICATES_P12_B64 }}
    p12-password: ${{ secrets.CERTIFICATES_P12_PASS }}

- name: Build for Device
  run: |
    xcodebuild -project Apps/MyApp/MyApp.xcodeproj \
      -scheme MyApp \
      -sdk iphoneos \
      -destination 'generic/platform=iOS' \
      -derivedDataPath ${{ env.DERIVED_DATA }} \
      DEVELOPMENT_TEAM=${{ secrets.DEVELOPMENT_TEAM }} \
      -allowProvisioningUpdates \
      build
```

## Export .p12 Certificate

```bash
# List identities
security find-identity -v -p codesigning

# Export (will prompt for password)
security export -k ~/Library/Keychains/login.keychain-db \
    -t identities \
    -f pkcs12 \
    -o certificate.p12

# Base64 encode for GitHub Secret
base64 -i certificate.p12 | pbcopy
```

## TestFlight Deployment

```yaml
- name: Archive
  run: |
    xcodebuild archive \
      -project Apps/MyApp/MyApp.xcodeproj \
      -scheme MyApp \
      -archivePath .build/MyApp.xcarchive \
      DEVELOPMENT_TEAM=${{ secrets.DEVELOPMENT_TEAM }}

- name: Export IPA
  run: |
    xcodebuild -exportArchive \
      -archivePath .build/MyApp.xcarchive \
      -exportPath .build/export \
      -exportOptionsPlist ExportOptions.plist

- name: Upload to TestFlight
  run: |
    xcrun altool --upload-app \
      --type ios \
      --file .build/export/MyApp.ipa \
      --apiKey ${{ secrets.APP_STORE_API_KEY_ID }} \
      --apiIssuer ${{ secrets.APP_STORE_ISSUER_ID }}
```

## macOS Notarization

```yaml
- name: Notarize
  run: |
    xcrun notarytool submit MyApp.zip \
      --key ${{ secrets.APP_STORE_API_KEY_P8 }} \
      --key-id ${{ secrets.APP_STORE_API_KEY_ID }} \
      --issuer ${{ secrets.APP_STORE_ISSUER_ID }} \
      --wait

- name: Staple
  run: xcrun stapler staple MyApp.app
```

## Required Secrets Summary

| Secret | Purpose | How to Get |
|--------|---------|------------|
| `DEVELOPMENT_TEAM` | Team ID | Apple Developer Portal |
| `CERTIFICATES_P12_B64` | Signing cert | Export from Keychain |
| `CERTIFICATES_P12_PASS` | Cert password | Set during export |
| `APP_STORE_API_KEY_ID` | API key ID | App Store Connect |
| `APP_STORE_ISSUER_ID` | Issuer ID | App Store Connect |
| `APP_STORE_API_KEY_P8` | API key file | App Store Connect |

## Caching Dependencies

```yaml
- name: Cache SPM
  uses: actions/cache@v4
  with:
    path: .build
    key: ${{ runner.os }}-spm-${{ hashFiles('Package.resolved') }}
    restore-keys: ${{ runner.os }}-spm-
```

## Matrix Builds

```yaml
strategy:
  matrix:
    destination:
      - 'platform=iOS Simulator,name=iPhone 16 Pro'
      - 'platform=iOS Simulator,name=iPad Pro 13-inch'

steps:
  - name: Build
    run: xcodebuild ... -destination '${{ matrix.destination }}'
```
