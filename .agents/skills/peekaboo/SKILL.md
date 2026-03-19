---
name: peekaboo
description: Capture and automate macOS UI with the Peekaboo CLI.
homepage: https://peekaboo.boo
metadata:
  {
    "openclaw":
      {
        "emoji": "👀",
        "os": ["darwin"],
        "requires": { "bins": ["peekaboo"] },
        "install":
          [
            {
              "id": "brew",
              "kind": "brew",
              "formula": "steipete/tap/peekaboo",
              "bins": ["peekaboo"],
              "label": "Install Peekaboo (brew)",
            },
          ],
      },
  }
---

# Peekaboo

Peekaboo is a full macOS UI automation CLI: capture/inspect screens, target UI
elements, drive input, and manage apps/windows/menus. Commands share a snapshot
cache and support `--json`/`-j` for scripting. Run `peekaboo` or
`peekaboo <cmd> --help` for flags; `peekaboo --version` prints build metadata.
Tip: run via `polter peekaboo` to ensure fresh builds.

## Features (all CLI capabilities, excluding agent/MCP)

Core

- `bridge`: inspect Peekaboo Bridge host connectivity
- `capture`: live capture or video ingest + frame extraction
- `clean`: prune snapshot cache and temp files
- `config`: init/show/edit/validate, providers, models, credentials
- `image`: capture screenshots (screen/window/menu bar regions)
- `learn`: print the full agent guide + tool catalog
- `list`: apps, windows, screens, menubar, permissions
- `permissions`: check Screen Recording/Accessibility status
- `run`: execute `.peekaboo.json` scripts
- `sleep`: pause execution for a duration
- `tools`: list available tools with filtering/display options

Interaction

- `click`: target by ID/query/coords with smart waits
- `drag`: drag & drop across elements/coords/Dock
- `hotkey`: modifier combos like `cmd,shift,t`
- `move`: cursor positioning with optional smoothing
- `paste`: set clipboard -> paste -> restore
- `press`: special-key sequences with repeats
- `scroll`: directional scrolling (targeted + smooth)
- `swipe`: gesture-style drags between targets
- `type`: text + control keys (`--clear`, delays)

System

- `app`: launch/quit/relaunch/hide/unhide/switch/list apps
- `clipboard`: read/write clipboard (text/images/files)
- `dialog`: click/input/file/dismiss/list system dialogs
- `dock`: launch/right-click/hide/show/list Dock items
- `menu`: click/list application menus + menu extras
- `menubar`: list/click status bar items
- `open`: enhanced `open` with app targeting + JSON payloads
- `space`: list/switch/move-window (Spaces)
- `visualizer`: exercise Peekaboo visual feedback animations
- `window`: close/minimize/maximize/move/resize/focus/list

Vision

- `see`: annotated UI maps, snapshot IDs, optional analysis

Global runtime flags

- `--json`/`-j`, `--verbose`/`-v`, `--log-level <level>`
- `--no-remote`, `--bridge-socket <path>`

## Quickstart (happy path)

```bash
peekaboo permissions
peekaboo list apps --json
peekaboo see --annotate --path /tmp/peekaboo-see.png
peekaboo click --on B1
peekaboo type "Hello" --return
```

## Common targeting parameters (most interaction commands)

- App/window: `--app`, `--pid`, `--window-title`, `--window-id`, `--window-index`
- Snapshot targeting: `--snapshot` (ID from `see`; defaults to latest)
- Element/coords: `--on`/`--id` (element ID), `--coords x,y`
- Focus control: `--no-auto-focus`, `--space-switch`, `--bring-to-current-space`,
  `--focus-timeout-seconds`, `--focus-retry-count`

## Common capture parameters

- Output: `--path`, `--format png|jpg`, `--retina`
- Targeting: `--mode screen|window|frontmost`, `--screen-index`,
  `--window-title`, `--window-id`
- Analysis: `--analyze "prompt"`, `--annotate`
- Capture engine: `--capture-engine auto|classic|cg|modern|sckit`

## Common motion/typing parameters

- Timing: `--duration` (drag/swipe), `--steps`, `--delay` (type/scroll/press)
- Human-ish movement: `--profile human|linear`, `--wpm` (typing)
- Scroll: `--direction up|down|left|right`, `--amount <ticks>`, `--smooth`

## Examples

### See -> click -> type (most reliable flow)

```bash
peekaboo see --app Safari --window-title "Login" --annotate --path /tmp/see.png
peekaboo click --on B3 --app Safari
peekaboo type "user@example.com" --app Safari
peekaboo press tab --count 1 --app Safari
peekaboo type "supersecret" --app Safari --return
```

### Target by window id

```bash
peekaboo list windows --app "Visual Studio Code" --json
peekaboo click --window-id 12345 --coords 120,160
peekaboo type "Hello from Peekaboo" --window-id 12345
```

### Capture screenshots + analyze

```bash
peekaboo image --mode screen --screen-index 0 --retina --path /tmp/screen.png
peekaboo image --app Safari --window-title "Dashboard" --analyze "Summarize KPIs"
peekaboo see --mode screen --screen-index 0 --analyze "Summarize the dashboard"
```

### Live capture (motion-aware)

```bash
peekaboo capture live --mode region --region 100,100,800,600 --duration 30 \
  --active-fps 8 --idle-fps 2 --highlight-changes --path /tmp/capture
```

### App + window management

```bash
peekaboo app launch "Safari" --open https://example.com
peekaboo window focus --app Safari --window-title "Example"
peekaboo window set-bounds --app Safari --x 50 --y 50 --width 1200 --height 800
peekaboo app quit --app Safari
```

### Menus, menubar, dock

```bash
peekaboo menu click --app Safari --item "New Window"
peekaboo menu click --app TextEdit --path "Format > Font > Show Fonts"
peekaboo menu click-extra --title "WiFi"
peekaboo dock launch Safari
peekaboo menubar list --json
```

### Mouse + gesture input

```bash
peekaboo move 500,300 --smooth
peekaboo drag --from B1 --to T2
peekaboo swipe --from-coords 100,500 --to-coords 100,200 --duration 800
peekaboo scroll --direction down --amount 6 --smooth
```

### Keyboard input

```bash
peekaboo hotkey --keys "cmd,shift,t"
peekaboo press escape
peekaboo type "Line 1\nLine 2" --delay 10
```

Notes

- Requires Screen Recording + Accessibility permissions.
- Use `peekaboo see --annotate` to identify targets before clicking.

## Shotty workflow

For this repo, use Peekaboo primarily for app launch, app switching, hotkeys, clicks,
and drags. The reliable local flow is:

```bash
./scripts/install-app.sh
peekaboo permissions
peekaboo app switch --to Shotty
peekaboo hotkey --keys "cmd,shift,s"
peekaboo drag --from-coords 3000,300 --to-coords 3600,800 --duration 800
```

What this validates in Shotty:

- The app builds, installs, and launches successfully.
- The global capture hotkey is active.
- The full-screen selection overlay appears.
- Dragging a region dismisses the overlay and returns to the editor.

## Shotty-specific targeting tips

- Shotty exposes multiple windows. The main editor window is the large floating panel;
  menu bar helper windows are tiny 38x24 windows and should be ignored for interaction.
- `peekaboo list windows --app Shotty --json` is the quickest way to distinguish the
  editor window from the menu bar windows.
- If you need deterministic tool selection, Shotty's tool buttons are accessible through
  macOS Accessibility even when `peekaboo see` is unavailable.
- On the verified layout from 2026-03-18, the tool switcher buttons appear in this order:
  `Text`, `Pencil`, `Rectangle`, `Circle`, `Highlight`.
- Shotty also supports local numeric shortcuts in the editor window:
  `1` = Text, `2` = Pencil, `3` = Rectangle, `4` = Circle, `5` = Highlight.

## Current limitations on this machine

Verified on 2026-03-18 with:

- Shotty installed via `./scripts/install-app.sh`
- Peekaboo `3.0.0-beta3`

What currently works:

- `peekaboo permissions`
- `peekaboo list apps --json`
- `peekaboo list windows --app Shotty --json`
- `peekaboo app switch --to Shotty`
- `peekaboo hotkey --keys "cmd,shift,s"`
- `peekaboo click --coords ...`
- `peekaboo drag --from-coords ... --to-coords ...`

What is currently unreliable or broken:

- `peekaboo see --window-id ...`
- `peekaboo image --window-id ...`
- `peekaboo see --app Shotty ...` for the main editor window
- `peekaboo image --app Shotty ...` for the main editor window

Observed failure mode:

- The command hangs and reports `SWIFT TASK CONTINUATION MISUSE: _createCheckedThrowingContinuation(_:) leaked its continuation without resuming it.`

Practical consequence:

- Do not depend on Peekaboo's own screenshot or annotated UI-map capture for Shotty's
  main editor window on this machine.
- Use Peekaboo for input automation, then use native macOS capture as the evidence source.

## Recommended fallback for visual verification

If Peekaboo can drive the UI but not capture the editor window, use macOS `screencapture`:

```bash
peekaboo list windows --app Shotty --json
screencapture -x -l 2610 /tmp/shotty-window.png
```

Notes:

- Replace `2610` with the current large editor `window_id`.
- If `screencapture` silently produces no file, switch back to Shotty first and retry:

```bash
peekaboo app switch --to Shotty
screencapture -x -l 2610 /tmp/shotty-window.png
```

## What we can and cannot test today

Can test with confidence:

- App launch/build/install
- Shotty app activation and window discovery
- Global screenshot hotkey handling
- Overlay appearance and drag-based region capture
- Basic annotation tool activation
- Drag-driven annotation creation for shape tools
- Undo hotkey behavior after annotation changes

Cannot fully test with confidence using the current Peekaboo build alone:

- Annotated `see` snapshots of the Shotty editor
- Peekaboo-captured editor screenshots
- Fine-grained element targeting inside the editor canvas via `see`
- Inline text annotation entry, because focus in the transient text editor is not
  reliably preserved when using `peekaboo type`

## Tips and tricks

- Prefer `peekaboo app switch --to Shotty` before any input or capture step. Shotty is a
  menu bar app and can lose frontmost status easily.
- Use `peekaboo list windows --app Shotty --json` after triggering `cmd,shift,s`:
  overlay windows show up as full-screen, high-level windows; the editor remains the
  medium-sized floating panel.
- For annotation smoke tests, `Rectangle` is easier to verify than `Text` because it does
  not depend on transient text-field focus.
- If `peekaboo type` is needed, first focus the target with `peekaboo click`, then type
  immediately. Avoid extra window-targeting flags if they steal focus back to the window
  rather than the inline editor.
- If a `see` or `image` command hangs, kill the stuck Peekaboo process before continuing:

```bash
ps -axo pid,command | rg 'peekaboo (see|image)'
kill <pid> ...
```

- Use native evidence files under `/tmp` when comparing state changes across actions.
  For example, capture before/after images and compare hashes:

```bash
md5 /tmp/before.png /tmp/after.png
```
