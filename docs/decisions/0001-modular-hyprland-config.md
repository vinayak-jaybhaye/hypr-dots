# 0001 - Modular Hyprland Configuration

**Date**: 2026-06-14
**Status**: Accepted

## Context

Hyprland supports both single-file and multi-file configuration via the `source` directive. A single large config becomes difficult to navigate and modify safely.

## Decision

Split hyprland.conf into multiple sourced files:

- **hyprland.conf**: core settings (monitor, programs, look & feel, input)
- **exec.conf**: autostart applications (exec-once directives)
- **keybinds.conf**: all key bindings including submaps
- **windowrules.conf**: window rules (currently empty, placeholder for growth)
- **hypridle.conf**, **hyprlock.conf**, **hyprpaper.conf**, **hyprsunset.conf**: separate tool configs

The source directives are placed at the **bottom** of hyprland.conf so that variables like `$terminal` and `$menu` are defined before being used in keybinds.conf.

## Alternatives Considered

- **Single file**: harder to maintain as the config grows; risky to edit one section without accidentally affecting another.
- **Deeper nesting**: over-engineering for the current size of the configuration.

## Consequences

- Each concern is isolated. Agents can modify keybinds without touching core settings.
- Source order matters — variables must be defined before sourced files that use them.

## Future Considerations

- If the config grows significantly, consider further splitting (e.g., `animations.conf`, `decoration.conf`).
- Always keep source directives at the bottom of hyprland.conf.
