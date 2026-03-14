# Phase 1 Checklist: Foundation

## Mission

Complete the full foundation phase for Shotty. Do not stop at scaffolding only. Finish the entire phase, verify it, write the handoff for the next phase, and commit all changes before ending your work.

## Product context

Shotty is a minimal macOS screenshot app. The target flow is:

1. User presses `Command` + `Shift` + `S`.
2. User selects an area of the screen.
3. Shotty captures that region.
4. Shotty opens a glassy preview/editor window.
5. User can annotate with text, pencil, rectangle, circle, highlight.
6. `Command` + `C` copies the final image.
7. `Command` + `S` opens save dialog.
8. `Esc` cancels capture or closes editor.
9. `Command` + `Z` and `Shift` + `Command` + `Z` perform undo/redo in the editor.

This phase is only the foundation needed to enable later phases.

## Required reading before coding

- Read [PLAN.md](/Users/mishca/scripts/shotty/PLAN.md) in full.
- Review the current codebase before making assumptions.
- There is no prior handoff for Phase 1.

## Phase goal

Create a native macOS app foundation in Swift that is ready for capture, annotation, and export work in later phases.

## Required deliverables

- Xcode project or Swift package-backed macOS app scaffold committed in the repo
- Native macOS app entry point
- Basic window/app lifecycle wired up
- Glass-styled editor window shell with placeholder canvas area
- Global shortcut registration for `Command` + `Shift` + `S`
- Permissions flow skeleton for screen capture access
- Core architecture folders/types created for future phases
- Clear README section or developer notes for how to run the app locally

## Implementation checklist

- Choose the native app structure and create the project files.
- Use Swift as the implementation language.
- Use SwiftUI for the main UI shell.
- Add AppKit bridges where necessary for window behavior and global hotkey support.
- Create the editor window shell with a strong glass/material appearance and minimal chrome.
- Add a placeholder canvas area sized for future screenshot preview.
- Create a minimal toolbar or tool strip shell with placeholder controls for future annotation tools.
- Wire `Esc` behavior in the shell where appropriate, even if full close logic is stubbed.
- Register the global `Command` + `Shift` + `S` shortcut.
- Make the shortcut invoke a clear placeholder capture action if actual capture is not yet implemented.
- Add the screen capture permission request/check flow skeleton.
- Create initial app architecture types such as `HotkeyManager`, `CaptureCoordinator`, `EditorWindowController`, `ScreenshotService`, `ExportService`, and annotation model placeholders.
- Keep the structure clean enough that future agents can implement the remaining phases without reorganizing everything.
- Add concise comments only where the intent is not obvious.

## Verification checklist

- Build the app successfully.
- Launch the app successfully.
- Confirm the editor window shell appears and is visually aligned with the glassy minimal direction.
- Confirm the global shortcut is registered and triggers the placeholder capture path.
- Confirm the permission flow does not crash, even if it is only a skeleton in this phase.
- Confirm the project can be run by another agent from a clean checkout with documented steps.

## Completion checklist

- Review your own changes for obvious structural issues before stopping.
- Write `plan/handoffs/phase-1-handoff.md` for the Phase 2 agent.
- In that handoff, explain what foundation was built, what is intentionally stubbed, and what Phase 2 must pick up next.
- If anything was blocked, failed, or compromised, document it in the handoff and in your final summary.
- Commit all changes with a clear non-interactive git commit before ending the phase.

## Required handoff contents

- Current app structure
- Run/build instructions
- What parts of capture are stubbed versus working
- Known technical debt introduced in Phase 1
- Any blockers or open questions for Phase 2

## Definition of done

This phase is done only when the app foundation exists, builds, runs, has the hotkey path wired, has the glass editor shell in place, has the handoff doc written, and all changes are committed.
