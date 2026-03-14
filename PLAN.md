# Shotty Plan

## Product Summary

Shotty is a minimal macOS screenshot app with one primary flow:

1. Press `Command` + `Shift` + `S`.
2. Select a screen region with a reticle-style capture overlay.
3. Open a small preview/editor window with the captured image.
4. Annotate with:
   - Text
   - Freehand pencil
   - Rectangle
   - Circle
   - Highlight
   - Undo/redo
5. Press `Command` + `C` to copy the final image to the clipboard.
6. Press `Command` + `S` to open a save panel and export to a user-chosen folder.

Non-goals:

- Screenshot history/library
- Cloud sync
- OCR
- Sharing integrations
- Multiple export formats in v1
- Full image editing beyond basic annotation

## Recommended Stack

Build Shotty as a native macOS app in Swift.

### Why native Swift/AppKit/SwiftUI

- Global shortcuts, screen capture permissions, clipboard access, and save panels are all first-class macOS concerns.
- The glass-heavy UI direction maps directly to current Apple UI frameworks.
- Annotation performance is simpler and more predictable with native image and drawing APIs.
- This app is intentionally narrow in scope, so cross-platform tooling would add complexity without payoff.

### Concrete tech choices

- Language: Swift
- UI shell: SwiftUI
- Windowing and advanced macOS integration: AppKit bridges where needed
- Screen capture: ScreenCaptureKit
- Region selection overlay: custom transparent fullscreen AppKit window
- Annotation rendering: Core Graphics + AppKit drawing layers
- Clipboard: `NSPasteboard`
- Save flow: `NSSavePanel`
- Persistence: none in v1 beyond transient in-memory editor state

## Important Assumption

I could not verify a specific public macOS dependency named `Reticle` that cleanly matches this use case. For planning, I am treating "use Reticle" as "use a reticle-style region selection overlay."

If you meant a specific package or repo, confirm it before implementation. Otherwise we should build this piece ourselves.

## UX Plan

### Capture flow

- Global shortcut activates capture mode from anywhere.
- All displays dim slightly.
- The user drags to select a rectangle.
- The selection shows:
  - thin bright border
  - size readout
  - subtle glass HUD
- `Esc` cancels capture.
- Mouse-up captures immediately and opens the preview window.

### Preview/editor window

- Small floating utility-style window.
- Strong glass treatment with restrained chrome.
- Large image canvas centered inside.
- Minimal vertical or top toolbar for annotation tools.
- Keyboard-first behavior:
  - `Command` + `C`: copy flattened image
  - `Command` + `S`: save with `NSSavePanel`
  - `Command` + `Z`: undo
  - `Shift` + `Command` + `Z`: redo
  - `Esc`: close editor without saving
  - `Delete`: remove selected annotation

### Annotation tools

- Text
  - Click to place text box
  - Default font tuned for macOS readability
- Pencil
  - Smooth freehand path
- Rectangle
  - Stroke only in v1
- Circle
  - Stroke only in v1
- Highlight
  - Semi-transparent fill stroke with multiply-style look

## Visual Direction

Target: very glassy, minimal, clean, modern macOS utility.

### Materials

- Use macOS glass/material views for shell surfaces.
- Avoid dense panels and hard dividers.
- Keep controls sparse with strong spacing.

### Color system

- Base accents: deep vibrant purple
- Contrast accent: yellow-gold for high-emphasis states
- Default annotation colors should stay restrained:
  - purple
  - yellow-gold
  - white

Suggested palette:

- Purple: `#5B21B6`
- Purple bright: `#6D28D9`
- Gold: `#F5C542`
- Gold bright: `#FFD84D`
- Text on glass: near-white with adaptive opacity

### Window styling

- Rounded corners
- Vibrant blurred background
- Thin translucent strokes
- Soft shadow, not heavy shadow
- Toolbar icons should feel quiet until hovered/selected

## Architecture

### Core modules

- `HotkeyManager`
  - Registers global `Command` + `Shift` + `S`
- `CaptureCoordinator`
  - Starts capture flow
  - Requests permissions
  - Owns capture session lifecycle
- `SelectionOverlayWindow`
  - Fullscreen transparent overlay across displays
  - Handles drag-selection UX
- `ScreenshotService`
  - Uses ScreenCaptureKit to capture the selected region
- `EditorWindowController`
  - Opens and manages the preview/editor window
- `AnnotationCanvas`
  - Displays screenshot
  - Hosts vector annotations
- `ExportService`
  - Copies flattened image to clipboard
  - Saves flattened image through `NSSavePanel`

### Data model

- `CapturedImage`
  - pixel image
  - capture rect
  - display scale
- `Annotation`
  - shared protocol/base type
- `TextAnnotation`
- `PathAnnotation`
- `RectAnnotation`
- `EllipseAnnotation`
- `HighlightAnnotation`
- `EditorDocument`
  - captured image
  - annotation array
  - selected tool
  - selected annotation

### Rendering approach

- Keep annotations as vector data while editing.
- Flatten only on copy/save.
- This preserves crisp output and makes future undo/redo straightforward.

## Permissions and Platform Notes

- Screen capture permission is required for actual screenshot capture.
- Global shortcut implementation on macOS may need AppKit/Carbon-level integration rather than pure SwiftUI.
- App sandbox should allow user-selected file access so `NSSavePanel` works cleanly for arbitrary save locations.

## Delivery Plan

### Phase 1: foundation

- Create native macOS app scaffold
- Add floating editor window shell
- Add global shortcut registration
- Add permissions flow

### Phase 2: capture

- Build multi-display selection overlay
- Capture selected region
- Open preview window with image

### Phase 3: annotation

- Implement annotation model
- Add pencil, rectangle, circle, text, highlight
- Add selection, deletion, tool switching, and undo/redo

### Phase 4: export

- Flatten image for clipboard copy
- Flatten image for save
- Add keyboard shortcuts inside editor

### Phase 5: polish

- Glass styling
- Cursor states
- Retina correctness
- Empty/error states
- Performance pass for large screenshots

## Test Plan

- Verify capture works on single-display and multi-display setups.
- Verify Retina and non-Retina coordinate mapping.
- Verify `Command` + `C` copies the annotated image, not the raw screenshot.
- Verify `Command` + `S` opens a save panel and writes valid PNG output.
- Verify permission-denied behavior is recoverable and understandable.
- Verify tools preserve correct layering and do not blur the base screenshot.

## Open Decisions

- Confirm whether "Reticle" means a specific dependency or just the capture overlay behavior.
- Confirm whether annotation shapes should be outline-only in v1, or allow fill for rectangle/circle.
