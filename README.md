# Shotty

Shotty is a native macOS screenshot utility being built in phases. Phase 1 establishes the app shell, editor window, global hotkey path, and screen-capture permission skeleton.

## Current foundation

- Swift package-backed macOS app in [`Package.swift`](/Users/mishca/scripts/shotty/Package.swift)
- SwiftUI editor shell hosted inside an AppKit floating window controller
- Global `Command` + `Shift` + `S` hotkey registration via Carbon
- Screen Recording permission check/request skeleton
- Placeholder capture image flow that exercises the editor and export scaffolding

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

## Phase 1 behavior

- The editor window opens on launch as the working shell for later phases.
- Press `Command` + `Shift` + `S` while Shotty is running to trigger the placeholder capture path.
- If Screen Recording permission has not been granted yet, Shotty requests it and updates the editor status.
- Copy/save controls work only after the placeholder image has been loaded through the hotkey path.

## Notes

- The real region-selection overlay and screenshot capture implementation are intentionally deferred to Phase 2.
- On this machine, `swift build` hit a local linker mismatch (`ld: unknown option: -no_warn_duplicate_libraries`). The verified build path for this repo is `xcodebuild`, which uses Xcode's linker and succeeds cleanly.
