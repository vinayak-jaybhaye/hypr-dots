# 0012 — Share theme definitions across native application configurations

## Context

Decision 0004 established Catppuccin Mocha as the desktop palette. Colors were repeated in two terminal formats, Hyprland Lua, Hyprlock, Mako, Waybar JSON and GTK styles. A second theme would have duplicated functional settings such as urgency timeouts, bar orientation and window rules.

## Decision

Keep Mocha as the default and discover themes by their TOML manifests. A palette, optional style overrides and optional artwork are enough to add a theme. Shared adapters translate values to each application's native format. Native includes keep behavioral configuration in the checkout. Wpaperd's small TOML config is rendered because it lacks includes.

Extend the deployment in decisions 0003 and 0011 with stable per-user application directories. Publish a complete generation through one atomic symlink replacement. Record the selected theme inside that generation. Use supported reload mechanisms for long-lived applications and read on launch for transient ones.

## Alternatives Considered

Maintaining whole per-theme app directories would duplicate keybindings and layouts. A GTK-only theme would miss terminal ANSI palettes, compositor rules and notifications. A third-party template engine or a theme daemon would introduce a dependency for a job performed only on install and switch.

## Consequences

Each theme has one source of truth and can be validated offline. Python 3.11 or newer reads TOML and Arch's libpng utilities validate artwork. Portable deployment requires the linker once per installation. Foot picks up the theme in new terminals, and Hyprlock applies it on the next lock. The [theme guide](../theming.md) covers the other reload boundaries.
