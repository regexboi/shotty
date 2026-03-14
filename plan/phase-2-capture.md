# Phase 2 Checklist: Capture

## Mission

Complete the full capture phase for Shotty. Do not leave capture half-integrated. Finish the entire phase, verify it, write the handoff for the next phase, and commit all changes before ending your work.

## Required reading before coding

- Read [PLAN.md](/Users/mishca/scripts/shotty/PLAN.md) in full.
- Read [phase-1-foundation.md](/Users/mishca/scripts/shotty/plan/phase-1-foundation.md) for context.
- Read [phase-1-handoff.md](/Users/mishca/scripts/shotty/plan/handoffs/phase-1-handoff.md) before making changes.
- Review the codebase and understand how Phase 1 was implemented before editing anything.

## Phase goal

Implement the region-selection and screenshot-capture flow so the global shortcut leads to a real captured image shown in the editor window.

## Required deliverables

- Fullscreen transparent selection overlay across displays
- Reticle-style drag selection experience
- Cancel flow on `Esc`
- Selected-region screenshot capture using the chosen native approach
- Correct coordinate handling for display scaling
- Captured image delivered into the editor window
- Clear failure handling for denied permission or capture errors

## Implementation checklist

- Review the Phase 1 architecture and preserve it unless there is a compelling reason to change it.
- If you need to restructure code from Phase 1, keep the change minimal and document why in the handoff.
- Implement a fullscreen overlay window or windows that cover all displays.
- Dim the background while keeping the interaction precise and responsive.
- Show a clear selection rectangle with polished feedback while dragging.
- Include basic measurements or helpful HUD feedback if practical without bloating the UI.
- Support cancel via `Esc`.
- On mouse release, capture the selected region and route it into the editor.
- Ensure the editor window opens or updates with the captured image.
- Handle screen capture permission failures gracefully.
- Handle no-selection or tiny-selection cases sensibly.
- Validate Retina and multi-display coordinate mapping carefully.
- Keep the UX minimal and aligned with the existing visual direction.

## Verification checklist

- Build and run successfully.
- Trigger capture via `Command` + `Shift` + `S`.
- Select a region on a single display and verify the correct image appears in the editor.
- If possible, test multi-display behavior and verify coordinate correctness.
- Verify `Esc` cancels capture cleanly with no orphaned overlay windows.
- Verify permission-denied behavior is understandable and recoverable.
- Verify the app remains stable after multiple capture attempts in one session.

## Completion checklist

- Review the implementation for coordinate bugs and lifecycle leaks before stopping.
- Write `plan/handoffs/phase-2-handoff.md` for the Phase 3 agent.
- In that handoff, explain exactly how capture works, what assumptions it makes, and any edge cases not fully solved.
- If anything was blocked, failed, or compromised, document it in the handoff and in your final summary.
- Commit all changes with a clear non-interactive git commit before ending the phase.

## Required handoff contents

- Capture flow architecture
- Overlay/window behavior details
- Coordinate system caveats
- Permission behavior
- Known capture bugs or edge cases
- What Phase 3 can assume about the incoming image/editor state

## Definition of done

This phase is done only when the shortcut launches a real selection flow, a real screenshot is captured, the editor receives the image, the handoff doc is written, and all changes are committed.
