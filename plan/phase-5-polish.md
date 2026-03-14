# Phase 5 Checklist: Polish

## Mission

Complete the full polish phase for Shotty. This phase closes the app for v1. Finish the entire phase, verify it, write the final handoff, and commit all changes before ending your work.

## Required reading before coding

- Read [PLAN.md](/Users/mishca/scripts/shotty/PLAN.md) in full.
- Read [phase-4-export.md](/Users/mishca/scripts/shotty/plan/phase-4-export.md) for context.
- Read [phase-4-handoff.md](/Users/mishca/scripts/shotty/plan/handoffs/phase-4-handoff.md) before making changes.
- Review the full codebase and understand current rough edges before editing anything.

## Phase goal

Polish the app into a coherent, minimal, glassy macOS utility and close remaining quality gaps without adding scope.

## Required deliverables

- Strong final glass/material styling across the app
- Refined spacing, states, and interactions
- Stability pass on capture, editor, annotation, undo/redo, and export
- Better edge-case handling where needed
- Final documentation and handoff status for the completed v1

## Implementation checklist

- Review the whole app and identify the highest-value polish fixes.
- Refine the window styling, materials, spacing, controls, and icon states.
- Ensure the visual system stays minimal and aligned with the purple and yellow-gold direction.
- Remove placeholder UI or dead code left from earlier phases.
- Tighten keyboard interactions and focus behavior.
- Fix high-value bugs that block a credible v1 experience.
- Improve empty, error, and denied-permission states where needed.
- Validate repeated use across multiple captures in one session.
- Do not add unrelated features or widen scope.
- Update developer-facing docs if setup or behavior changed materially.

## Verification checklist

- Build and run successfully.
- Exercise the full user flow from shortcut to capture to annotation to copy/save.
- Verify undo/redo, `Esc`, delete, copy, and save all still work.
- Verify the app looks intentional and consistent, not partially scaffolded.
- Verify there are no obvious crashes in normal use.
- Verify the remaining limitations are documented rather than hidden.

## Completion checklist

- Review the full app for regressions before stopping.
- Write `plan/handoffs/phase-5-handoff.md` as the final project handoff/status document.
- In that handoff, summarize overall completion status, remaining bugs, and what would come next after v1 if work continues.
- If anything was blocked, failed, or compromised, document it in the handoff and in your final summary.
- Commit all changes with a clear non-interactive git commit before ending the phase.

## Required handoff contents

- Final app status
- Remaining known issues
- Remaining design or technical debt
- Suggested next steps after v1
- Exact verification performed

## Definition of done

This phase is done only when the app feels cohesive, the highest-value polish issues are addressed, the final handoff doc is written, and all changes are committed.
