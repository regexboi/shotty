# Phase 4 Checklist: Export

## Mission

Complete the full export phase for Shotty. Do not stop after wiring one output path. Finish the entire phase, verify it, write the handoff for the next phase, and commit all changes before ending your work.

## Required reading before coding

- Read [PLAN.md](/Users/mishca/scripts/shotty/PLAN.md) in full.
- Read [phase-3-annotation.md](/Users/mishca/scripts/shotty/plan/phase-3-annotation.md) for context.
- Read [phase-3-handoff.md](/Users/mishca/scripts/shotty/plan/handoffs/phase-3-handoff.md) before making changes.
- Review the codebase and understand the current editor and annotation model before editing anything.

## Phase goal

Implement final image export so the edited screenshot can be copied to the clipboard or saved to a user-selected location.

## Required deliverables

- Image flattening pipeline from screenshot plus annotations
- `Command` + `C` clipboard export of final image
- `Command` + `S` save flow using `NSSavePanel`
- Valid saved image output, preferably PNG unless a different format is already justified
- Clear handling for export failures

## Implementation checklist

- Review the annotation model and design export around the current editable representation.
- Flatten the captured image and annotations only at export time.
- Implement clipboard copy of the flattened image via native macOS clipboard APIs.
- Implement save via `NSSavePanel`.
- Save to a sane default format and filename.
- Ensure saved output matches the edited preview as closely as practical.
- Preserve image quality and correct pixel dimensions.
- Avoid mutating editor state during export.
- Keep keyboard shortcuts aligned with the product spec.
- Surface errors clearly if copy or save fails.

## Verification checklist

- Build and run successfully.
- Capture an image, add annotations, and verify `Command` + `C` copies the final annotated image.
- Paste the copied image into another app and verify it is correct.
- Verify `Command` + `S` opens the save panel.
- Save an image and verify the file is valid and visually correct.
- Verify repeated copy/save actions do not corrupt state or produce stale output.
- Verify export uses the edited image, not the raw screenshot.

## Completion checklist

- Review the flattening/export code for quality loss or stale-state issues before stopping.
- Write `plan/handoffs/phase-4-handoff.md` for the Phase 5 agent.
- In that handoff, explain the export pipeline, output assumptions, and any remaining issues that polish work should address.
- If anything was blocked, failed, or compromised, document it in the handoff and in your final summary.
- Commit all changes with a clear non-interactive git commit before ending the phase.

## Required handoff contents

- Export architecture
- Clipboard behavior
- Save panel behavior
- File format details
- Known export discrepancies or bugs
- What Phase 5 should polish or regression-test most carefully

## Definition of done

This phase is done only when copy and save both work on the final annotated image, the handoff doc is written, and all changes are committed.
