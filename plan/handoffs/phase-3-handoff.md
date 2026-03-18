# Phase 3 Handoff For Phase 4

## What exists now

Shotty now has a real in-editor annotation system on top of the captured screenshot.

Current editor behavior:

1. A successful capture still lands in `EditorDocument.capturedImage`.
2. The editor renders the screenshot as the immutable base layer.
3. All annotations stay separate as vector-like data in `EditorDocument.annotations`.
4. The tool switcher supports text, pencil, rectangle, circle, and highlight.
5. Clicking an existing annotation selects it. `Delete` removes the selected annotation.
6. `Command` + `Z` undoes annotation changes. `Shift` + `Command` + `Z` reapplies them.
7. Text annotations edit inline through a temporary `NSTextField`.

## Annotation data model

- `Sources/Shotty/Models/Annotations.swift` now owns the annotation model.
- `AnnotationSnapshot` is the single enum used in document state:
  - `.text(TextAnnotation)`
  - `.path(PathAnnotation)`
  - `.rect(RectAnnotation)`
  - `.ellipse(EllipseAnnotation)`
  - `.highlight(HighlightAnnotation)`
- Every annotation has a stable `UUID`, is `Equatable`, and stores its geometry in image-space coordinates.
- Image-space here means logical points relative to `CapturedImage.image.size`, not window pixels and not screen-global coordinates.
- The base image is still `NSImage` sized to the capture rect in points. The capture’s preferred raster scale is still available as `CapturedImage.displayScale`.

## Rendering and interaction approach

- `Sources/Shotty/Editor/AnnotationCanvasView.swift` owns canvas interaction.
- The screenshot is displayed with aspect-fit scaling inside the editor.
- A local `CanvasLayout` converts between view coordinates and image-space coordinates.
- Non-text annotations render in a SwiftUI `Canvas`.
- Text annotations render as overlay views so inline editing can use an AppKit text field.
- Pencil and highlight keep raw sampled points and render through a smoothed quadratic path (`smoothedPath(for:)`).
- Annotations are layered strictly in array order. New annotations append to the end and therefore render on top of older ones.

## Undo/redo implementation approach

- Undo/redo lives in `EditorViewModel`.
- The model records only finished document mutations, not every drag sample.
- `EditorHistoryState` stores:
  - `annotations`
  - `selectedAnnotationID`
- The canvas keeps drag drafts locally and calls `viewModel.addAnnotation(...)` only when the gesture ends.
- Text editing commits as a single mutation when the inline editor finishes.
- Undo/redo clears any active inline text edit before restoring state.

## Tool behavior and limitations

- Text:
  - click empty canvas to place a new text annotation
  - click a selected text annotation while the text tool is active to edit it inline
  - single-line only in Phase 3
  - empty committed text deletes the annotation
- Pencil:
  - freehand stroke with smoothed rendering
- Rectangle:
  - stroke-only rectangle
- Circle:
  - stroke-only ellipse
- Highlight:
  - freehand stroke rendered with lower opacity and multiply blending

Current scope limits:

- Selection is delete-only. There is no move, resize, recolor, or z-order editing yet.
- Text uses a single-line inline editor and no multiline box layout.
- Rectangle hit testing currently treats the full interior as selectable, not just the border stroke.
- Freehand selection is implemented via widened stroked-path hit testing rather than control points or handles.

## Selection and deletion details

- Selection state is `EditorDocument.selectedAnnotationID`.
- Hit testing walks annotations in reverse order, so topmost visible annotations win.
- Selected annotations render with a dashed white outline.
- `Delete` and forward-delete are handled in `EditorPanel` unless the current first responder is the inline text field editor.

## Keyboard behavior

- `EditorPanel.performKeyEquivalent(with:)` handles:
  - `Command` + `Z`
  - `Shift` + `Command` + `Z`
- `EditorPanel.keyDown(with:)` handles delete keys.
- The panel intentionally does not hijack those shortcuts while an `NSTextView` field editor is first responder, so inline text editing can keep normal text-edit behavior.

## Rendering and hit-testing caveats

- Text bounds are measured approximately from AppKit font metrics. They are close enough for selection and inline editing, but not yet typographically exact.
- Because the canvas stores logical-point coordinates, Phase 4 must scale by `CapturedImage.displayScale` when flattening into raster output.
- Highlight and pencil use smoothed curves for rendering and hit testing, so flattening should use the same helper path construction or it will not match the editor exactly.
- I verified the implementation by successful `xcodebuild` and a brief launch of the built app. I did not complete a full interactive manual annotation pass in this environment, so tool feel and mixed-input edge cases still need live desktop verification.

## What Phase 4 should use for flattening/export

- Use `EditorDocument.annotations` as the source of truth.
- Treat annotation coordinates as image-space points relative to `CapturedImage.image.size`.
- Raster export should create a target bitmap sized from:
  - `CapturedImage.image.size.width * CapturedImage.displayScale`
  - `CapturedImage.image.size.height * CapturedImage.displayScale`
- When drawing annotations into that bitmap, multiply coordinates and line widths by `displayScale`.
- Reuse the current shape semantics:
  - text positioned by top-left origin
  - pencil/highlight from `smoothedPath(for:)`
  - rectangle and ellipse from their stored rects
- Do not flatten from the visible editor view size. That would bake in window scaling and reduce output fidelity.

## Known remaining gaps

- Copy/save still export the raw capture only. Phase 4 needs to replace that with flattened annotated output.
- There is no automated test coverage yet.
- I left an unrelated pre-existing modification in `Sources/Shotty/Core/Capture/ScreenshotService.swift` untouched. Phase 4 should continue to avoid overwriting it unless that work is intentionally incorporated.
