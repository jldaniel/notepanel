#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d dist/NotePanel.app ]]; then
  "$ROOT/scripts/build-release.sh"
fi

VERSION="$(defaults read "$ROOT/dist/NotePanel.app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo "1.0")"
DMG_NAME="NotePanel-${VERSION}.dmg"
STAGING=".dmg-staging"

rm -rf "$STAGING" "$DMG_NAME"
mkdir -p "$STAGING"
cp -R dist/NotePanel.app "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "NotePanel" -srcfolder "$STAGING" -ov -format UDZO "$DMG_NAME"
rm -rf "$STAGING"

echo "Created: $ROOT/$DMG_NAME"
