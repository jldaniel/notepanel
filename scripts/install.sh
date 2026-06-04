#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d dist/NotePanel.app ]]; then
  "$ROOT/scripts/build-release.sh"
fi

echo "Quitting any running NotePanel..."
osascript -e 'quit app "NotePanel"' 2>/dev/null || true
sleep 0.5

echo "Installing to /Applications..."
rm -rf /Applications/NotePanel.app
cp -R dist/NotePanel.app /Applications/NotePanel.app

echo "Launching NotePanel..."
open -a /Applications/NotePanel.app

echo "Installed: /Applications/NotePanel.app"
