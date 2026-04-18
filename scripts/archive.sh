#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." &> /dev/null && pwd)"
cd "$REPO_ROOT"

ARCHIVE_PATH="build/GymFlow.xcarchive"
EXPORT_PATH="build/export"

echo "==> Cleaning previous archive output"
rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH"

echo "==> Archiving GymFlow (Release)"
xcodebuild archive \
    -project GymFlow.xcodeproj \
    -scheme GymFlow \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic

echo "==> Exporting .ipa for App Store Connect"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist scripts/ExportOptions.plist \
    -allowProvisioningUpdates

echo
echo "==> Done."
echo "Archive: $ARCHIVE_PATH"
echo "Export:  $EXPORT_PATH"
echo
echo "Next: open the archive in Xcode Organizer, or upload with:"
echo "    xcrun altool --upload-app -f \"$EXPORT_PATH\"/*.ipa -t ios --apiKey <KEY> --apiIssuer <ISSUER>"
