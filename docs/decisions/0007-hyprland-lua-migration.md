# 0007 — Migration from Hyprlang to Native Hyprland Lua API

**Date**: 2026-11-04
**Status**: Accepted (Supersedes 0001 regarding .conf syntax)

## Context

Hyprland introduced a native Lua configuration and scripting engine (`hl.*` namespace, `hyprland.lua`), replacing the legacy `hyprlang` (`.conf`) syntax. To maintain forward-compatibility with modern Hyprland releases (0.56+), reduce parsing overhead, leverage native type validation, and allow programmatic configuration and event hooks, the compositor configuration needed to be migrated to the official Lua API while maintaining strict functional equivalence and zero visual/behavioral regression.

## Decision

Migrate the entire Hyprland compositor configuration from `.conf` files to modular Lua scripts, organized as:

1. `hyprland.lua`: Primary entry point configured with monitors, environment variables, general settings, window decoration, animations/curves, input parameters, gestures, and module loaders.
2. `programs.lua`: Defines default user applications (`terminal`, `fileManager`, `menu`) cleanly exported as a Lua table for consumption by other modules.
3. `exec.lua`: Manages autostart services using the native `hl.on("hyprland.start", ...)` event hook (direct replacement for `exec-once`).
4. `keybinds.lua`: Configures all keyboard shortcuts, dispatchers (`hl.dsp`), submaps (`hl.define_submap`), mouse buttons, multimedia keys, and scratchpad/special workspace bindings.
5. `windowrules.lua`: Declares per-window layout and sizing rules using `hl.window_rule`.

External daemon configs (`hypridle.conf`, `hyprlock.conf`, `hyprsunset.conf`, `hyprpaper.conf`) remain standalone `.conf` files because they are parsed by their respective independent daemons and are not part of Hyprland compositor syntax.

The original `.conf` files (`hyprland.conf`, `exec.conf`, `keybinds.conf`, `windowrules.conf`) are archived in `config/hypr/legacy/` for backup and historical reference. Hyprland 0.57+ natively detects and boots directly from `hyprland.lua`.

## Alternatives Considered

- **Keep legacy `.conf` syntax**: While still supported as a fallback, legacy syntax misses out on native Lua capabilities, scriptability, type validation, and upstream long-term alignment.
- **Monolithic single-file `hyprland.lua`**: Rejected in favor of modularity; separating programs, autostart, keybinds, and window rules maintains clean separation of concerns.
- **Converting daemon configs (`hyprlock`, `hypridle`, `hyprsunset`)**: Rejected because these utilities do not use the Hyprland compositor Lua parser and require their native configuration files.

## Consequences

- Fully aligns with official Hyprland Lua architecture and upstream defaults.
- Clean Lua module loading using standard `require()` and dynamic `package.path` resolution.
- Keybindings, submaps, and autostart sequence remain functionally and visually identical.
- Configuration can be verified offline via `Hyprland --verify-config`.
- Documentation across the repository is updated to reflect Lua configuration files.

