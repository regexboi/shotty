# Phase 3 Checklist: Annotation

## Mission

Complete the full annotation phase for Shotty. Do not implement only some tools. Finish the entire phase, verify it, write the handoff for the next phase, and commit all changes before ending your work.

## Required reading before coding

- Read [PLAN.md](/Users/mishca/scripts/shotty/PLAN.md) in full.
- Read [phase-2-capture.md](/Users/mishca/scripts/shotty/plan/phase-2-capture.md) for context.
- Read [phase-2-handoff.md](/Users/mishca/scripts/shotty/plan/handoffs/phase-2-handoff.md) before making changes.
- Review the codebase and understand the editor and capture flow before editing anything.

## Phase goal

Implement the full annotation system in the editor, including all required tools plus selection, deletion, and undo/redo.

## Required deliverables

- Annotation model with stable editing behavior
- Pencil tool
- Text tool
- Rectangle tool
- Circle tool
- Highlight tool
- Selection behavior for annotations
- Delete behavior for selected annotation
- Undo/redo with keyboard shortcuts
- Tool switching UI integrated into the editor

## Implementation checklist

- Review how the captured image is currently displayed and extend it without degrading image quality.
- Keep annotations editable as vector-like data until export time.
- Implement an annotation model that can support selection and undo/redo cleanly.
- Add pencil drawing with reasonably smooth paths.
- Add text placement and text editing behavior suitable for a minimal v1.
- Add rectangle drawing.
- Add circle drawing.
- Add highlight drawing with transparent marker-like appearance.
- Add annotation selection behavior.
- Add deletion via `Delete`.
- Add `Command` + `Z` undo and `Shift` + `Command` + `Z` redo.
- Ensure undo/redo works across the supported annotation actions.
- Add a minimal tool switcher that fits the glassy visual style.
- Ensure annotation layering behaves predictably.
- Avoid overbuilding advanced editing features that are outside scope.

## Verification checklist

- Build and run successfully.
- Capture an image and verify all five tools work in the editor.
- Verify selection works for non-freehand annotations and any intended freehand behavior.
- Verify deletion removes the selected annotation only.
- Verify undo/redo works repeatedly and restores correct state.
- Verify the base screenshot stays sharp and is not permanently mutated during editing.
- Verify the editor remains responsive after creating multiple annotations.

## Completion checklist

- Review the implementation for state-management issues before stopping.
- Write `plan/handoffs/phase-3-handoff.md` for the Phase 4 agent.
- In that handoff, explain the annotation model, editor assumptions, and any limitations in text editing or selection behavior.
- If anything was blocked, failed, or compromised, document it in the handoff and in your final summary.
- Commit all changes with a clear non-interactive git commit before ending the phase.

## Required handoff contents

- Annotation data model
- Undo/redo implementation approach
- Tool behavior and limitations
- Selection/deletion behavior details
- Any rendering or hit-testing caveats
- What Phase 4 should use when flattening/exporting images

## Definition of done

This phase is done only when all required tools are implemented, selection and deletion work, undo/redo works through keyboard shortcuts, the handoff doc is written, and all changes are committed.
