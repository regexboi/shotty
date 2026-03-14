# Shotty Build Phases

This folder contains the execution checklist for each build phase of Shotty.

## How to use these docs

- Each phase document is self-contained and should be read in full before work starts.
- The assigned agent must complete the entire phase, not a partial subset.
- At the end of the phase, the agent must write a handoff document for the next phase in `plan/handoffs/`.
- Starting with Phase 2, the assigned agent must read the prior phase's handoff document first, then review the codebase before making changes.
- Every phase ends with a required commit.
- Any blockers, compromises, or failed attempts must be documented both in the phase summary and in the handoff doc.

## Phase documents

- [phase-1-foundation.md](/Users/mishca/scripts/shotty/plan/phase-1-foundation.md)
- [phase-2-capture.md](/Users/mishca/scripts/shotty/plan/phase-2-capture.md)
- [phase-3-annotation.md](/Users/mishca/scripts/shotty/plan/phase-3-annotation.md)
- [phase-4-export.md](/Users/mishca/scripts/shotty/plan/phase-4-export.md)
- [phase-5-polish.md](/Users/mishca/scripts/shotty/plan/phase-5-polish.md)

## Handoff documents

- Store handoffs in `plan/handoffs/`.
- Use one file per phase, named `phase-<n>-handoff.md`.
- Each handoff should be written for the next agent, not as a changelog for the current one.
