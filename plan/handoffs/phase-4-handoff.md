# Phase 4 Handoff For Phase 5

## What exists now

Shotty now exports the final edited image instead of the raw capture.

Current export behavior:

1. The editor still keeps annotations live and editable in `EditorDocument.annotations`.
2. Copy and save both flatten the current screenshot plus annotations at export time.
3. `Command` + `C` copies the flattened annotated image to the macOS pasteboard.
4. `Command` + `S` opens an `NSSavePanel` and writes a PNG of the flattened annotated image.
5. Export errors now surface as explicit user-facing status messages instead of silent failure.

## Export architecture

- `Sources/Shotty/Core/Export/ExportService.swift` owns the export pipeline.
- Export does not mutate editor state.
- `renderedImage(for:)` is the core flattening entry point.
- That method:
  - reads `CapturedImage.image` as the immutable base image
  - creates a fresh `NSBitmapImageRep` sized to the capture’s raster dimensions
  - assigns the bitmap rep the capture’s logical size in points
  - creates a flipped `NSGraphicsContext`
  - draws the base image first
  - draws annotations in array order on top
- Export uses the existing image-space annotation coordinates directly, so the output matches the editor’s logical geometry instead of the visible window size.

## Clipboard behavior

- `copyCurrentImage(document:)` now throws explicit `ExportError`s.
- On success it writes the flattened `NSImage` to `NSPasteboard.general`.
- On failure the editor status shows a concrete export message.
- `Command` + `C` is handled in `EditorPanel.performKeyEquivalent(with:)` when the panel is not currently handing keyboard input to the inline text field editor.

## Save panel behavior

- `saveCurrentImage(document:from:completion:)` now reports:
  - `.saved(URL)`
  - `.cancelled`
  - `.failure(ExportError)`
- Saves use `NSSavePanel` with PNG output.
- The current default filename is still `Shotty Capture.png`.
- The view model updates status for all three outcomes, including cancellation and actual write failures.
- `Command` + `S` is also handled in `EditorPanel.performKeyEquivalent(with:)`, again only when the inline text field editor is not first responder.

## File format details

- Saved output is PNG.
- Copy output is an `NSImage` containing the flattened raster.
- Raster dimensions come from the underlying captured image representation when available, with `CapturedImage.displayScale` as fallback sizing.
- The flattened image should preserve the original screenshot sharpness better than exporting from the visible window size because export rasterization happens against the capture-sized bitmap, not the canvas frame.

## Rendering assumptions and caveats

- Export reuses the same annotation semantics as the editor:
  - text via top-left origin
  - pencil/highlight via `smoothedPath(for:)`
  - rectangle and ellipse via stored rects
- Highlight export uses multiply blending with the same low-alpha stroke intent as the editor.
- Text export currently uses AppKit `NSFont.systemFont` drawing, which is close to the editor preview but not guaranteed to be pixel-identical to SwiftUI’s rounded text rendering.
- Keyboard export shortcuts intentionally do not override the inline text field when it is actively editing. In that state, standard text-field copy behavior still wins.

## Known export discrepancies or remaining issues

- I verified Phase 4 by successful `xcodebuild` after the export and shortcut changes. I did not complete a full live manual copy/paste/save round-trip in this environment, so clipboard output and saved-file fidelity still need desktop validation.
- The default save filename is static and not timestamped yet.
- There is still no automated regression coverage around flattening, clipboard output, or file writing.
- The editor window is no longer draggable from the screenshot canvas. If Phase 5 wants easier window movement, add a deliberate drag region instead of restoring background dragging everywhere.
- There is still an unrelated pre-existing modification in `Sources/Shotty/Core/Capture/ScreenshotService.swift` that I left untouched.

## What Phase 5 should polish or regression-test most carefully

1. Compare saved/copied output against the live editor for text alignment, highlight opacity, and stroke thickness.
2. Manually verify `Command` + `C` by pasting into Preview, Notes, or another image-capable app.
3. Manually verify `Command` + `S` for cancel, overwrite, and repeated saves.
4. Check Retina and mixed-scale captures to confirm exported pixel density stays sharp.
5. Decide whether Shotty should expose a better filename strategy and a dedicated window-drag affordance outside the canvas.
