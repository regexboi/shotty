# Shotty

Shotty is a native macOS screenshot utility being built in phases. Phase 2 is now in place, which means the global shortcut launches a real region-selection overlay and routes an actual screenshot into the editor window.

## Current status

- Swift package-backed macOS app in [`Package.swift`](/Users/mishca/scripts/shotty/Package.swift)
- SwiftUI editor shell hosted inside an AppKit floating window controller
- Global `Command` + `Shift` + `S` hotkey registration via Carbon
- Real fullscreen selection overlay across active displays
- ScreenCaptureKit-backed region capture with a macOS 15.2 fast path and an older-runtime fallback
- Raw image copy/save actions for the current capture while annotation/export phases are still in progress

## Run locally

### Xcode

1. Open [`Package.swift`](/Users/mishca/scripts/shotty/Package.swift) in Xcode.
2. Select the `Shotty` scheme.
3. Run the app on `My Mac`.

### CLI

Build with Xcode's toolchain:

```bash
xcodebuild -scheme Shotty -destination 'platform=macOS' -derivedDataPath .build/xcode build
```

Launch the built app executable:

```bash
.build/xcode/Build/Products/Debug/Shotty
```

Install a reusable app bundle to `/Applications`:

```bash
./scripts/install-app.sh
```

## Phase 2 behavior

- The editor window opens on launch as the working shell for later phases.
- Press `Command` + `Shift` + `S` while Shotty is running to open the selection overlay.
- Shotty runs as a menu bar utility, so it can stay resident without a Dock icon.
- Drag a region on any active display, or across displays, to capture it.
- Press `Esc` during selection to cancel with no capture.
- If Screen Recording permission has not been granted yet, Shotty requests it and updates the editor status.
- Copy/save controls work after a real screenshot has been loaded into the editor.

## Notes

- Annotation tools are still scaffold-only and land in Phase 3.
- Copy/save still operate on the raw captured image; flattening annotations lands in Phase 4.
- On this machine, `swift build` hit a local linker mismatch (`ld: unknown option: -no_warn_duplicate_libraries`). The verified build path for this repo is `xcodebuild`, which uses Xcode's linker and succeeds cleanly.
