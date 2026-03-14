# Phase 1 Handoff For Phase 2

## What exists now

Shotty is now a buildable native macOS app scaffold implemented as a Swift package. The app entry point is SwiftUI, but the main editor surface is managed by AppKit through `EditorWindowController` so later phases can keep using a custom floating utility-style window.

Current structure:

- `Sources/Shotty/App/`
  - app entry point and lifecycle wiring
  - `ShottyApplication` owns the core managers
- `Sources/Shotty/Core/Hotkey/`
  - Carbon-based global hotkey registration for `Command` + `Shift` + `S`
- `Sources/Shotty/Core/Capture/`
  - `CaptureCoordinator`
  - `ScreenshotService` placeholder image generator
  - `SelectionOverlayWindow` stub for the future region selector
- `Sources/Shotty/Core/Export/`
  - placeholder copy/save behavior for the current image
- `Sources/Shotty/Editor/`
  - glass-style shell view, view model, and AppKit window controller
- `Sources/Shotty/Models/`
  - initial document, captured image, tool, and annotation placeholder types
- `Sources/Shotty/Support/`
  - palette/theme constants

## Build and run

Preferred local build path:

```bash
xcodebuild -scheme Shotty -destination 'platform=macOS' -derivedDataPath .build/xcode build
```

Launch:

```bash
.build/xcode/Build/Products/Debug/Shotty
```

Opening `Package.swift` directly in Xcode and running the `Shotty` scheme also works.

## What is working vs stubbed

Working:

- app launches
- editor shell opens on launch
- hotkey registration succeeds
- pressing `Command` + `Shift` + `S` routes into `CaptureCoordinator`
- Screen Recording permission is checked and can be requested
- after permission is granted, a generated placeholder image is loaded into the editor
- placeholder copy/save flows work against that generated image
- `Esc` closes the editor window
- clicking the dock icon reopens the editor window

Stubbed or intentionally deferred:

- `SelectionOverlayWindow` does not create a real fullscreen overlay yet
- no real screen-region selection exists
- `ScreenshotService` does not use ScreenCaptureKit yet
- annotation tools are UI/model scaffolding only
- undo/redo, keyboard editor commands, and selection logic are not implemented yet

## What Phase 2 should do next

1. Replace `SelectionOverlayWindow.beginPlaceholderSelection()` with a real multi-display transparent overlay that supports drag selection and `Esc` cancel.
2. Replace `ScreenshotService.makePlaceholderImage()` with real capture logic using ScreenCaptureKit and correct coordinate mapping.
3. When capture completes, inject a real `CapturedImage` into `EditorDocument` and preserve the existing editor shell.
4. Keep the AppKit window controller architecture unless there is a strong reason to change it; it already supports the floating/glass editor direction.

## Technical debt introduced in Phase 1

- Permission state uses a simple `UserDefaults` flag to distinguish "never prompted" from "prompted but still not authorized". That is sufficient for the skeleton, but not authoritative system state.
- The verified CLI build path relies on `xcodebuild`. On this machine, `swift build` fails because of a linker mismatch outside the repo.
- `ExportService` is still placeholder-oriented and writes the raw current image without future annotation flattening.
- The placeholder image generator exists only to exercise the window/export path and should be removed once real capture is in place.

## Open questions / blockers

- No functional blocker for Phase 2 was found.
- The top-level plan mentions a reticle-style overlay; implementation should proceed as a custom overlay window unless the user later specifies a concrete dependency named "Reticle".
