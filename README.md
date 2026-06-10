# NotePanel

A small macOS menu-bar app for scratch-pad notes that render Markdown. Stickies doesn't render Markdown, and I wanted something a bit more organized—so I vibed out this sidebar panel.

**Note:** I'm not a Swift dev. This is not intended to be an App Store product, this is a personal project I built for myself, to fill a gap I had. It's MIT-licensed if you want to fork or learn from it.

## Requirements

- macOS 14+
- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

`NotePanel.xcodeproj` is **not** committed. After cloning, run `xcodegen generate` to create it. Swift Package dependencies resolve on the first build.

## Setup (one time)

1. Install Xcode from the App Store and open it once.
2. Install command line tools if needed:
   ```sh
   xcode-select --install
   ```
3. Generate the Xcode project:
   ```sh
   xcodegen generate
   ```
4. Open `NotePanel.xcodeproj` in Xcode once to confirm signing (select your Apple ID under Signing & Capabilities if prompted).
5. Build and run with `Cmd+R` to verify.

## Build from the command line

```sh
xcodegen generate
xcodebuild \
  -scheme NotePanel \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath .build/DerivedData \
  build

open .build/DerivedData/Build/Products/Debug/NotePanel.app
```

## Usage

- **Left-click** the menu bar icon to toggle the side panel.
- **Right-click** the menu bar icon for the full menu.
- A global shortcut toggles the panel (even when another app is focused) — **⌘⇧P** by default, configurable in **Preferences…**.
- **⌘N** creates a new note when NotePanel's menu is active.
- **Click** a note title or body to edit; **Done**, **Escape**, or **⌘Return** saves.
- Edit the note title directly in the card header. Titles are plain text and do not render Markdown.
- Use the chevron in a note header to collapse or expand a note. Collapse state is saved locally with the note.
- Drag a note by the **grip icon** (≡) in its header to reorder.
- Delete via the **×** button or context menu; **Copy Note** in the context menu copies a note as Markdown.
- **Preferences…** (`⌘,`) adjusts panel width, top spacing, and launch at login.

## Privacy

The app runs in the macOS App Sandbox. Notes are stored locally on your Mac via SwiftData, in the app's container (Application Support/NotePanel). Nothing is sent to a server.

Markdown previews do not load remote images. Links in notes remain clickable and will open in your browser.

## Install from source

Build a Release app, copy it to `/Applications`, and launch it:

```sh
./scripts/install.sh
```

To build without installing:

```sh
./scripts/build-release.sh
open dist/NotePanel.app
```

### Launch at login

After installing to `/Applications`, open **Preferences…** from the menu bar and enable **Launch at login**. macOS may also list NotePanel under **System Settings → General → Login Items**.

Launch at login is off by default until you turn it on.

### Create a DMG (optional)

For a drag-to-Applications disk image on your machine:

```sh
./scripts/make-dmg.sh
open NotePanel-*.dmg
```

The DMG filename uses the app version from `Info.plist` (for example, `NotePanel-1.1.dmg`).

DMGs built this way are ad-hoc signed and not notarized. They are meant for personal use or for others building from this repo on their own Mac—not as a pre-built binary you distribute without Apple Developer ID signing and notarization.

## Third-party dependencies

- [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) (Swift Package Manager)

## License

MIT — see [LICENSE](LICENSE).

## Project structure

```
App/           AppKit shell (menu bar, panel, hotkey, settings)
Models/        SwiftData models
Views/         SwiftUI UI
Utilities/     Markdown rendering, notifications
scripts/       Build, install, and DMG helpers
```
