# AGENTS.md

Guidance for AI agents working in this repository. The README documents *what*
the plugin does; this file records *how* to change it without breaking it.

## What this is

An Omarchy shell plugin (Quickshell/QML), id `saigkill.tea-timer`: a tea
brewing countdown (3–10 minutes) as a bar widget with a selection panel. No
helper process, no network, no persisted state.

| File | Role |
|---|---|
| `manifest.json` | Plugin id, kind (`bar-widget`), entry point |
| `BarWidget.qml` | Owns all timer state, the tick timer, the ready notification, IPC |
| `Panel.qml` | UI only. Reads and calls through `hostWidget`; holds no state |
| `Model.js` | Pure logic (durations, clamping, formatting, message). Qt-free so it runs under node |

The structure and Quickshell APIs (`BarWidget`, `Panel`, `KeyboardPanel`,
`BarIconButton`, `PanelActionButton`, ...) are copied from the sibling plugins,
mainly `../omarchy-medical`. When unsure how an API behaves, look there
instead of guessing.

## Rules that matter

- **The countdown is based on an absolute end time** (`endMs`), not on
  decrementing a counter per tick. `remaining` is derived from `nowMs`, so
  timer jitter or a suspended shell cannot make it drift. Pause stores
  `pausedRemainingMs` and resume computes a new `endMs`. Keep it that way.
- **State lives on `BarWidget.qml` only.** The panel is loaded through a
  `Loader` and gets `hostWidget` injected (`injectPanel()`); it may be
  recreated, so never keep timer state in it.
- **The notification uses a fixed replace id (4242).** Each bar runs its own
  widget instance, so with several monitors each one fires; the fixed id makes
  the shell merge them into one toast. Do not replace it with a random id.
- **Do not write files into the plugin directory at runtime.** Quickshell
  watches it and reloads the plugin on any write, which would drop the open
  panel and the running timer. If persistence is ever added, use
  `~/.local/state/omarchy-tea-timer/` like `omarchy-medical` does.
- Minutes are always passed through `Model.clampMinutes()` (also for the IPC
  `setMinutes`). The selection is locked while a timer is running or paused.

## Testing

- `Model.js` is plain JS: test it with node (`eval` the file or add a
  `tests/test_model.js` like the sibling plugins).
- The QML cannot be run under node. Verify in the real shell: symlink the
  plugin into `~/.config/omarchy/plugins/saigkill.tea-timer`, add the widget
  to the bar, and watch the log for QML errors.
- For a fast manual test, temporarily lower `MIN_MINUTES` / use a short
  `totalMs`, and put the change back afterwards.
- Do not restart the shell from an agent session. It can kill the bar
  without relaunching it. Ask the user to do it.

## Conventions

- 2-space indent, `// ---- section ----` comment dividers, comments explain
  *why*, matching the sibling plugins.
- Plugin id prefix is `saigkill.`; IPC target and `moduleName` equal the id.
- Icons are Nerd Font glyphs (`` cup, `` play, `` pause,
  `` stop).
