# 0008 — Waybar Workspace Switching via ext/workspaces Protocol

**Date**: 2026-11-04
**Status**: Accepted

## Context

In Hyprland v0.56+ with the native Lua configuration manager (`hyprland.lua`), the compositor's IPC socket interprets raw `dispatch <cmd>` requests as Lua expressions (`return hl.dispatch(<cmd>)`). 

Waybar stable (`v0.15.0`)'s legacy `hyprland/workspaces` module was hardwired in C++ to send legacy text commands over the IPC socket (e.g., `dispatch workspace <id>` and `dispatch workspace e+1`). Under the Lua engine, `dispatch workspace 2` produces a Lua syntax error (`')' expected near '2'`) because `workspace 2` is not a valid Lua expression. As a result, clicking on workspace tabs in Waybar failed to switch workspaces.

## Decision

Migrate Waybar's workspace module from `hyprland/workspaces` to the standard Wayland `ext/workspaces` module in `config/waybar/modules/left.jsonc`:

1. **Native Wayland Protocol**: `ext/workspaces` uses Wayland's official `ext_workspace_manager_v1` and `ext_workspace_handle_v1.activate()` protocol, which Hyprland implements natively at the Wayland compositor level. Clicks switch workspaces directly without passing text commands through the IPC socket.
2. **Scroll Handlers**: Updated `on-scroll-up` and `on-scroll-down` to use the official Hyprland Lua dispatcher syntax:
   - `hyprctl dispatch 'hl.dsp.focus({ workspace = "e+1" })'`
   - `hyprctl dispatch 'hl.dsp.focus({ workspace = "e-1" })'`
3. **Styling Consistency**: Retained identical CSS IDs and classes (`#workspaces`, `#workspaces button`, `#workspaces button.active`, `#workspaces button.urgent`), maintaining Catppuccin Mocha styling without visual regression.

## Alternatives Considered

- **Upgrading to `waybar-git` via AUR**: Upstream Waybar PR #5013 adapts `hyprland/workspaces` for the Lua protocol, but requiring a `-git` AUR package breaks the goal of running on stable Arch repo packages (`waybar 0.15.0-3`).
- **Reverting to legacy Hyprlang (`.conf`)**: Rejected as it conflicts with the project goal of native Lua configuration.
- **Custom script buttons**: Unnecessary complexity and overhead compared to the built-in `ext/workspaces` protocol.

## Consequences

- Workspace clicking works reliably via the compositor's native Wayland protocol.
- Workspace scrolling works smoothly using the official Lua dispatchers.
- Maintains compatibility with stable Arch packages without needing AUR development builds.

