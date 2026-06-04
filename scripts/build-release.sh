#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

rm -rf dist

echo "Generating Xcode project..."
xcodegen generate

echo "Building Release..."
xcodebuild \
  -scheme NotePanel \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  build

APP_SRC=".build/DerivedData/Build/Products/Release/NotePanel.app"
if [[ ! -d "$APP_SRC" ]]; then
  echo "error: expected app at $APP_SRC" >&2
  exit 1
fi

mkdir -p dist
cp -R "$APP_SRC" dist/NotePanel.app

# Ad-hoc sign for local use when Developer ID signing is not configured
if ! codesign --verify --deep --strict dist/NotePanel.app 2>/dev/null; then
  echo "Applying ad-hoc code signature..."
  codesign --force --deep --sign - dist/NotePanel.app
fi

echo "Built: $ROOT/dist/NotePanel.app"
