# Phase 2 Handoff For Phase 3

## What exists now

Shotty now has a real capture flow instead of the Phase 1 placeholder path.

Current capture path:

1. `Command` + `Shift` + `S` routes into `CaptureCoordinator`.
2. Permission is checked with `CGPreflightScreenCaptureAccess()`.
3. If permission is available, the editor window is hidden and `SelectionOverlayWindow` presents one transparent fullscreen overlay panel per active display.
4. The user drags a region. The overlay dims the background, clears the selected area, draws a bright border/corner accents, shows crosshair reticle lines, and displays a small size HUD while dragging.
5. `Esc` cancels the session. Mouse-up with a tiny selection fails gracefully and reopens the editor with a message.
6. On a valid selection, the overlay tears down, Shotty waits 120 ms to avoid self-capturing the overlay, and `ScreenshotService` captures the region.
7. The resulting `CapturedImage` is stored in `EditorDocument`, and the editor window is shown with the new image.

## Key implementation details

### Capture flow architecture

- `CaptureCoordinator`
  - owns capture session state and blocks re-entrant captures with `isCaptureInProgress`
  - hides the editor during selection
  - restores the editor on cancel/failure/success
- `SelectionOverlayWindow`
  - manages a short-lived `Session`
  - creates one borderless `NSPanel` per `NSScreen`
  - uses screen-space points throughout selection tracking
- `ScreenshotService`
  - `macOS 15.2+`: uses `SCScreenshotManager.captureImage(in:)` for a display-agnostic multi-display capture
  - older runtimes: resolves `SCDisplay` metadata, captures each intersecting display region separately with `SCScreenshotManager.captureImage(contentFilter:configuration:)`, then composites the pieces into one `CGImage`

### Overlay/window behavior

- Overlay panels sit at `CGShieldingWindowLevel()`
- Panels join all spaces and fullscreen spaces via `collectionBehavior`
- Cursor is pushed to crosshair for the duration of the session
- `Esc` is handled both through the key window path and a local key monitor
- Selection coordinates are tracked in global screen coordinates, not per-window local coordinates

### Coordinate handling

- Selection rectangles are normalized and made integral in screen points before capture
- For the older-runtime fallback path, `sourceRect` is computed relative to each display’s origin in logical points
- Output pixels are sized from `intersection.size * backingScaleFactor`
- Multi-display fallback compositing uses the maximum intersecting display scale as the final canvas scale

This means mixed-scale multi-display captures should be correct geometrically, but lower-scale displays will be scaled up inside the final composite when another intersecting display has a higher backing scale.

## Permission behavior

- Permission state still uses the Phase 1 `UserDefaults` marker to distinguish “never prompted” from “prompted but not currently granted”
- Real authority still comes from `CGPreflightScreenCaptureAccess()`
- If permission is denied before capture or disappears later, Shotty reopens the editor and points the user to Screen Recording settings

## Known edge cases / risks

- I verified the implementation by clean `xcodebuild` and by launching the built binary briefly. I did not complete an interactive manual capture pass in this environment, so single-display, multi-display, and permission-denied UX still need human verification on a live desktop session.
- The 120 ms delay before capture is pragmatic. It is there to reduce the chance of the overlay appearing in the captured image.
- The fallback compositing path should handle display gaps by leaving transparent/empty pixels where no display content exists.
- The editor still holds only the latest capture. There is no capture history/state restoration.
- Copy/save still export the raw captured image. Annotation flattening is still Phase 4 work.

## What Phase 3 can assume

- `EditorDocument.capturedImage` will be populated with a real `NSImage` after successful capture
- `CapturedImage.captureRect` is the selected region in global screen points
- `CapturedImage.displayScale` is the preferred scale for the capture, not a guarantee that every pixel came from a single display scale
- The editor window will already reopen after capture and display the new image in the existing shell
- Tool selection UI and annotation model scaffolding from Phase 1 still exist and are unchanged structurally

## Suggested Phase 3 focus

1. Build annotation rendering on top of `document.capturedImage`.
2. Keep the current AppKit window controller and SwiftUI editor shell unless annotation behavior exposes a concrete limitation.
3. Treat the incoming image as the single source of truth for the editor canvas; no extra capture-session state should be needed.
