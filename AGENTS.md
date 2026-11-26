# AGENTS.md — AI Agent Onboarding

> **Read this file completely before making any changes to this repository.**

## Repository Overview

This is a Hyprland desktop environment dotfiles repository for a laptop running **Arch Linux**. The target hardware has a single built-in display (Samsung 0x4208, `eDP-1` on the reference machine, 1920×1200 @ 60 Hz). The repository manages all compositor, bar, terminal, notification, wallpaper, lock screen, and idle configurations through a symlink-based deployment model.

**Goals:**
- Single-command reproducible setup via `bootstrap.sh`
- Catppuccin Mocha theme consistency across all components
- Modular, maintainable configuration (split files, includes/imports)
- Laptop-optimized defaults (power management, brightness, touchpad)

**Core components:** Hyprland (compositor), Waybar (bar), Foot (default terminal), Kitty (network terminal), Wofi (launcher), Thunar (file manager), Mako (notifications), Wpaperd (wallpaper), Hypridle + Hyprlock (idle/lock), Hyprsunset (night mode).

---

## Architectural Rules

### Hyprland Lua Module Architecture

Hyprland uses a modular **native Lua configuration** system (`hyprland.lua`). The entry point is `config/hypr/hyprland.lua`, which initializes core settings and loads modular components via `require()`:

1. `programs.lua` — default user applications table (`terminal`, `fileManager`, `menu`)
2. `exec.lua` — autostart services using `hl.on("hyprland.start", function() ... end)`
3. `keybinds.lua` — keyboard shortcuts, submaps, mouse buttons, and media keys
4. `theme.lua` — applies the selected appearance through the native Lua API.
5. `windowrules.lua` — per-window rules using `hl.window_rule`

**Module Resolution:** `hyprland.lua` dynamically sets `package.path` so that modules inside `config/hypr/` resolve cleanly regardless of invocation directory. Legacy `.conf` files are archived in `config/hypr/legacy/`.

### Deployment paths

The linker discovers the checkout from its own location and deploys under `${XDG_CONFIG_HOME:-$HOME/.config}`. Scripts stay executable in Git. Reference them through the deployed `hypr/scripts` directory link. Waybar edge changes go under `${XDG_STATE_HOME:-$HOME/.local/state}/hypr-dots/`.

### Desktop settings

Keep each setting with its owner. The window in `scripts/settings.py` calls the existing theme and Waybar helpers and reads live service or hardware values. New project-only preferences go through `scripts/desktop_controls.py`. Settings manages night light and its login preference. Settings controls Mako DND and holds a logind idle inhibitor while Keep awake is enabled. Run `python3 tests/settings.py` for changes to these controls. Use `--gtk` in a graphical session to exercise the window. [Decision 0013](docs/decisions/0013-desktop-settings.md)

The Display page runs screen capture through `scripts/recording.py`. Keep the recorder bound to the application lifetime so closing the window leaves the stop control available on reopen. Monitor and region capture use wf-recorder. Workspace and window capture use the native portal picker. [Recording lifecycle](docs/decisions/0014-screen-recording.md) · [Capture sources](docs/decisions/0015-portal-recording.md)

### Waybar Module Architecture

Waybar uses a **two-level include pattern**:

**JSON (functional):** The root default and saved per-user position each select an orientation file. Both orientation files include these fragments, with vertical-specific overrides in `config-vertical.jsonc`:
- `modules/left.jsonc` — defines `modules-left` array + workspaces/window configs
- `modules/center.jsonc` — defines `modules-center` array + clock config
- `modules/right.jsonc` — defines `modules-right` array (module ordering)
- `modules/system.jsonc` — built-in module definitions (cpu, memory, battery, etc.)
- `modules/custom.jsonc` — custom module definitions (power, settings, power-btn)

**CSS (visual):** `style.css` imports via `@import`:
- `theme.css` — selected palette and typography
- `styles/base.css` — shared global styles
- `styles/modules.css` — per-module colors + hover effects
- `styles/states.css` — state-dependent styles (battery warning, muted, etc.) + blink animation
- `styles/workspaces.css` — workspace button styles

### Script ↔ Waybar Communication

The wattage module polls its helper. The stock bar has no signal-driven modules. Optional custom modules can use a status script and a dedicated real-time refresh signal.

### Color system

Themes live in `themes/<id>/theme.toml`. Mocha is the default. Keep functional config under `config/`, shared style defaults in `themes/defaults.toml`, and application-specific token mappings in `themes/templates/`. The linker creates per-user app directories. Edit sources in the checkout. Run `./scripts/theme.py validate` and `python3 tests/themes.py` for theme changes. See [theming](docs/theming.md).

## Modification Rules

### General

- **Never rename or move config files** without updating all references (module require paths in hyprland.lua, include paths in waybar config.jsonc, @import paths in style.css, script paths in keybinds.lua and custom.jsonc)
- **Always preserve existing comments** — they document intent and structure
- **Test shell scripts** with `bash -n <script>` before committing
- **Validate Lua syntax** with `luac -p <file>` and verify config with `Hyprland --verify-config`
- **Validate JSON** in any modified `.jsonc` files (trailing commas and `//` comments are allowed by waybar's JSONC parser, but malformed structure will break the bar)

### Adding a New Waybar Module

1. **Define the module** in `modules/system.jsonc` (built-in) or `modules/custom.jsonc` (custom)
2. **Add to the bar** by placing the module name in the appropriate array in `modules/left.jsonc`, `modules/center.jsonc`, or `modules/right.jsonc`
3. **Style the module** — add a CSS selector and color in `styles/modules.css`, add it to the shared background/hover rule block
4. **Add state styles** in `styles/states.css` if the module has states (e.g., warning, critical, enabled, disabled)
5. **If using a custom script**, create a status script in `scripts/` that outputs valid JSON, and if toggleable, create a toggle script that sends `pkill -RTMIN+N waybar` (use the next available RTMIN number — currently RTMIN+4 is the next free signal)

### Adding a New Keybind

- Add to `keybinds.lua` under the appropriate section comment block
- Follow the existing pattern: `hl.bind(keys, dispatcher_or_function, opts)`
- If adding a new section, use the existing comment banner style

### Adding a New Submap

- **CAUTION:** Submaps capture all keyboard input until explicitly exited
- Every submap created with `hl.define_submap("<name>", function() ... end)` must have an escape binding: `hl.bind("escape", hl.dsp.submap("reset"))`
- Submaps are entered via `hl.dsp.submap("<name>")`
- Test thoroughly after any submap changes using `Hyprland --verify-config`

### Adding an Autostart Service

- Add `hl.exec_cmd("<command>")` inside the `hl.on("hyprland.start", function() ... end)` block in `exec.lua`
- Place order-sensitive services (e.g., clipboard watchers) after the services they depend on

### Adding Window Rules

- Add to `windowrules.lua`
- Use the native `hl.window_rule` table syntax:
  ```lua
  hl.window_rule({
      match = { class = "^(app)$" },
      float = true,
      size = "800 600",
  })
  ```

---

## Files Requiring Special Caution

| File | Risk | Why |
|------|------|-----|
| `keybinds.lua` | **HIGH** | Contains submaps (opacity, mouse). Missing escape/reset bindings breaks ALL keybinds globally. |
| `exec.lua` | **MEDIUM** | Startup order matters — clipboard watchers must run after waybar for tray integration; polkit agent must start for privilege escalation. |
| `modules/right.jsonc` | **MEDIUM** | Module ordering directly controls visual bar layout. Adding modules here without definitions in system.jsonc/custom.jsonc causes waybar errors. |
| `themes/templates/waybar.css` | **MEDIUM** | CSS `@define-color` variables are used by every other stylesheet. Renaming or removing a variable breaks styles globally. |
| `link-configs.sh` | **HIGH** | Handles backup + symlink logic. Bugs here can delete existing user configs. The `--force` flag removes existing targets. |
| `hyprland.lua` | **MEDIUM** | Root compositor entry point. Syntax or type errors prevent Hyprland from starting. |

---

## Before Making Changes

1. **Read this file completely** (you're doing that now)
2. **Identify which component** you're modifying (Hyprland? Waybar? Scripts?)
3. **Check [docs/architecture.md](docs/architecture.md)** for dependency relationships between components
4. **Check [docs/repository-map.md](docs/repository-map.md)** to understand every file's purpose
5. **Understand the signal/refresh mechanism** if touching waybar scripts — a wrong signal number will refresh the wrong module or do nothing
6. **Check for hardcoded paths** — use the generic output rule for new hardware and match the panel description for hardware-specific settings

## After Making Changes

1. **Run `bash -n`** on any modified shell scripts to check syntax
2. **Run `luac -p` and `Hyprland --verify-config`** on any modified `.lua` files
3. **Verify JSON syntax** on any modified `.jsonc` files (e.g., `python3 -c "import json; json.load(open('file.jsonc'))"` — note: strip comments first if using strict JSON parsers)
4. **Update [docs/repository-map.md](docs/repository-map.md)** if files were added or removed
5. **Record significant architectural decisions** in `docs/decisions/NNNN-title.md`
6. **Update this file** if modification rules or architectural patterns changed

---

## Shell Scripting Style

- Use `#!/bin/sh` for POSIX-only scripts, `#!/usr/bin/env bash` only when bash features are needed (e.g., `[[ ]]`, arrays, process substitution)
- Use **tabs** for indentation (all existing scripts use tabs)
- JSON status scripts for Waybar **must** output valid JSON on stdout — `{"text":"…","tooltip":"…","class":"…"}`
- The wattage module uses plain text and an empty result when no battery rate is available.
- Toggle scripts should: check process with `pgrep`, toggle with `pkill`/restart, `sleep 0.1`, then signal waybar with `pkill -RTMIN+N waybar`
- Keep scripts minimal — the current scripts are 4–17 lines; don't over-engineer

## Config File Style

- **Hyprland configs:** 4-space indent, section comments with `### SECTION ###` banner style
- **Waybar JSON:** 2-space indent, JSONC format (comments allowed)
- **CSS:** 2-space indent, use `@define-color` variable references (`@blue`, `@red`, etc.) from the selected `theme.css` — never hardcode hex colors in `modules.css`, `states.css`, or `workspaces.css`
- **Shell scripts:** tabs for indentation, minimal comments, no unnecessary quoting of simple strings

## Decision Recording

For significant architectural decisions (changing the theme system, adding new components, restructuring the module pattern, etc.):

1. Create `docs/decisions/NNNN-title.md` (number sequentially: 0001, 0002, …)
2. Use this format:
   ```
   # NNNN — Title

   ## Context
   What prompted this decision?

   ## Decision
   What was decided?

   ## Alternatives Considered
   What else was considered and why was it rejected?

   ## Consequences
   What are the implications of this decision?
   ```
3. Decisions are append-only — never delete or modify past decisions, only supersede them with new ones.
