# 0004 - Catppuccin Mocha as Canonical Color Theme

**Date**: 2026-06-14
**Status**: Accepted

## Context

A consistent color theme across all components (bar, terminal, notifications, lock screen) creates a cohesive desktop experience.

## Decision

Use Catppuccin Mocha as the color theme throughout:

- **Waybar**: full palette defined as CSS `@define-color` variables in `styles/base.css`
- **Kitty**: Catppuccin Mocha colors hardcoded in `kitty.conf`
- **Hyprland**: border colors use the teal/green accent (`rgba(33ccffee) rgba(00ff99ee) 45deg`)
- **Hyprlock**: minimal styling with white text on background image
- **Mako**: empty config (uses defaults — not themed)

The canonical color definitions live in waybar `styles/base.css`. Kitty has its own copy because it doesn't support CSS variables.

## Alternatives Considered

- **Dracula**: popular but higher contrast than desired.
- **Nord**: cool-toned but limited accent variety.
- **Tokyo Night**: similar aesthetic but less ecosystem support.
- **Custom theme**: maximum control but high maintenance burden.

## Consequences

- Color consistency requires manual synchronization across components. There's no single color source that all tools read.
- Changing the theme requires updating: `base.css`, `kitty.conf`, and `hyprland.conf` border colors at minimum.

## Future Considerations

- Consider creating a `colors.conf` or `theme.sh` that generates component-specific color configs from a single source.
- Consider theming mako to match.
