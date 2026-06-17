# AGENTS.md — AI Agent Onboarding

> **Read this file completely before making any changes to this repository.**

## Repository Overview

This is a Hyprland desktop environment dotfiles repository for a laptop running **Arch Linux**. The target hardware has a single built-in display (`eDP-1`, 1920×1080 @ 60 Hz). The repository manages all compositor, bar, terminal, notification, wallpaper, lock screen, and idle configurations through a symlink-based deployment model.

**Goals:**
- Single-command reproducible setup via `bootstrap.sh`
- Catppuccin Mocha theme consistency across all components
- Modular, maintainable configuration (split files, includes/imports)
- Laptop-optimized defaults (power management, brightness, touchpad)

**Core components:** Hyprland (compositor), Waybar (bar), Kitty (terminal), Wofi (launcher), Thunar (file manager), Mako (notifications), Wpaperd (wallpaper), Hypridle + Hyprlock (idle/lock), Hyprsunset (night mode).

---

## Architectural Rules

### Config Sourcing Order

Hyprland loads `hyprland.conf` first, then sources these files **at the bottom** in this exact order:

1. `exec.conf` — autostart services
2. `keybinds.conf` — all keybinds and submaps
3. `windowrules.conf` — window rules

**This order matters.** Variables defined in `hyprland.conf` (like `$terminal`, `$fileManager`, `$menu`) must be defined before they're referenced in sourced files. Moving the `source` directives or reordering them can break the config.

### Waybar Module Architecture

Waybar uses a **two-level include pattern**:

**JSON (functional):** `config.jsonc` includes via the `"include"` array:
- `modules/left.jsonc` — defines `modules-left` array + workspaces/window configs
- `modules/center.jsonc` — defines `modules-center` array + clock config
- `modules/right.jsonc` — defines `modules-right` array (module ordering)
- `modules/system.jsonc` — built-in module definitions (cpu, memory, battery, etc.)
- `modules/custom.jsonc` — custom module definitions (power, hyprsunset, dnd, power-btn)

**CSS (visual):** `style.css` imports via `@import`:
- `styles/base.css` — Catppuccin Mocha `@define-color` variables + global styles
- `styles/modules.css` — per-module colors + hover effects
- `styles/states.css` — state-dependent styles (battery warning, muted, etc.) + blink animation
- `styles/workspaces.css` — workspace button styles

### Script ↔ Waybar Communication

Custom waybar modules use a **toggle/status pattern**:

1. **Status script** (e.g., `hyprsunset-status.sh`): outputs JSON `{"text":"…","tooltip":"…","class":"…"}` — waybar polls this via `exec`
2. **Toggle script** (e.g., `hyprsunset-toggle.sh`): toggles the process, then sends `pkill -RTMIN+N waybar` to trigger an immediate refresh
3. **Module config** specifies `"return-type": "json"` and `"signal": N` to listen for RTMIN+N

**Current signal assignments:**
| Signal | Module | Toggle Script |
|--------|--------|---------------|
| RTMIN+2 | `custom/hyprsunset` | `hyprsunset-toggle.sh` |
| RTMIN+3 | `custom/dnd` | `mako-dnd-toggle.sh` |

### Color System

- **Canonical source:** Catppuccin Mocha palette defined as CSS `@define-color` variables in `config/waybar/styles/base.css`
- **Kitty:** has its own copy of the same palette as `colorN` values in `kitty.conf`
- **Hyprland:** border colors are hardcoded hex in `hyprland.conf` `general {}` section (not Catppuccin — uses cyan/green gradient)
- **Hyprlock:** uses hardcoded `rgba()` values
- **Mako:** empty config — uses mako's built-in defaults

When changing the theme, all four locations (waybar base.css, kitty.conf, hyprland.conf borders, hyprlock.conf) must be updated independently.

---

## Modification Rules

### General

- **Never rename or move config files** without updating all references (source paths in hyprland.conf, include paths in waybar config.jsonc, @import paths in style.css, script paths in keybinds.conf and custom.jsonc)
- **Always preserve existing comments** — they document intent and structure
- **Test shell scripts** with `bash -n <script>` before committing
- **Validate JSON** in any modified `.jsonc` files (trailing commas and `//` comments are allowed by waybar's JSONC parser, but malformed structure will break the bar)

### Adding a New Waybar Module

1. **Define the module** in `modules/system.jsonc` (built-in) or `modules/custom.jsonc` (custom)
2. **Add to the bar** by placing the module name in the appropriate array in `modules/left.jsonc`, `modules/center.jsonc`, or `modules/right.jsonc`
3. **Style the module** — add a CSS selector and color in `styles/modules.css`, add it to the shared background/hover rule block
4. **Add state styles** in `styles/states.css` if the module has states (e.g., warning, critical, enabled, disabled)
5. **If using a custom script**, create a status script in `scripts/` that outputs valid JSON, and if toggleable, create a toggle script that sends `pkill -RTMIN+N waybar` (use the next available RTMIN number — currently RTMIN+4 is the next free signal)

### Adding a New Keybind

- Add to `keybinds.conf` under the appropriate section comment block
- Follow the existing pattern: `bind = $mainMod, KEY, action, args`
- If adding a new section, use the existing comment style: `########################` / `### SECTION NAME #####` / `########################`

### Adding a New Submap

- **CAUTION:** Submaps are the most fragile part of the keybind config
- Every `submap = <name>` must have a matching `submap = reset` to return to the default map
- If a submap is opened but never reset, ALL keybinds outside that submap stop working
- Always include an escape/cancel bind: `bind = , escape, submap, reset`
- Test thoroughly after any submap changes

### Adding an Autostart Service

- Add `exec-once = <command>` to `exec.conf`
- Place order-sensitive services (e.g., clipboard watchers) after the services they depend on
- Use `exec-once` (not `exec`) — `exec` re-runs on every config reload

### Adding Window Rules

- Add to `windowrules.conf`
- Use the unified window rule syntax: `windowrule = <rule> [value], match:<criteria> <regex>`

---

## Files Requiring Special Caution

| File | Risk | Why |
|------|------|-----|
| `keybinds.conf` | **HIGH** | Contains 2 submaps (opacity, mouse). Incorrect `submap`/`submap = reset` pairing breaks ALL keybinds globally. |
| `exec.conf` | **MEDIUM** | Startup order matters — clipboard watchers must run after waybar for tray integration; polkit agent must start for privilege escalation. |
| `modules/right.jsonc` | **MEDIUM** | Module ordering directly controls visual bar layout. Adding modules here without definitions in system.jsonc/custom.jsonc causes waybar errors. |
| `styles/base.css` | **MEDIUM** | CSS `@define-color` variables are used by every other stylesheet. Renaming or removing a variable breaks styles globally. |
| `link-configs.sh` | **HIGH** | Handles backup + symlink logic. Bugs here can delete existing user configs. The `--force` flag removes existing targets. |
| `hyprland.conf` | **MEDIUM** | `source` directives at the bottom load the entire config chain. Moving these above variable definitions breaks `$terminal`, `$fileManager`, `$menu` references. |

---

## Before Making Changes

1. **Read this file completely** (you're doing that now)
2. **Identify which component** you're modifying (Hyprland? Waybar? Scripts?)
3. **Check [docs/architecture.md](docs/architecture.md)** for dependency relationships between components
4. **Check [docs/repository-map.md](docs/repository-map.md)** to understand every file's purpose
5. **Understand the signal/refresh mechanism** if touching waybar scripts — a wrong signal number will refresh the wrong module or do nothing
6. **Check for hardcoded paths** — monitor `eDP-1` is hardcoded in `hyprland.conf`, `wpaperd/config.toml`, and `scripts/livewall.sh`

## After Making Changes

1. **Run `bash -n`** on any modified shell scripts to check syntax
2. **Verify JSON syntax** on any modified `.jsonc` files (e.g., `python3 -c "import json; json.load(open('file.jsonc'))"` — note: strip comments first if using strict JSON parsers)
3. **Update [docs/repository-map.md](docs/repository-map.md)** if files were added or removed
4. **Record significant architectural decisions** in `docs/decisions/NNNN-title.md`
5. **Update this file** if modification rules or architectural patterns changed

---

## Shell Scripting Style

- Use `#!/bin/sh` for POSIX-only scripts, `#!/usr/bin/env bash` only when bash features are needed (e.g., `[[ ]]`, arrays, process substitution)
- Use **tabs** for indentation (all existing scripts use tabs)
- Scripts that output for waybar **must** output valid JSON on stdout — `{"text":"…","tooltip":"…","class":"…"}`
- Toggle scripts should: check process with `pgrep`, toggle with `pkill`/restart, `sleep 0.1`, then signal waybar with `pkill -RTMIN+N waybar`
- Keep scripts minimal — the current scripts are 4–17 lines; don't over-engineer

## Config File Style

- **Hyprland configs:** 4-space indent, section comments with `### SECTION ###` banner style
- **Waybar JSON:** 2-space indent, JSONC format (comments allowed)
- **CSS:** 2-space indent, use `@define-color` variable references (`@blue`, `@red`, etc.) from `base.css` — never hardcode hex colors in `modules.css`, `states.css`, or `workspaces.css`
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
