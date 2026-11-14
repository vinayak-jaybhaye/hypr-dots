# 0009 — Dynamic Waybar Position Layouts (Horizontal vs. Vertical)

**Date**: 2026-11-14
**Status**: Accepted

## Context

Waybar previously only supported a fixed `top` horizontal position. Switching Waybar to vertical positions (`left` or `right`) by simply changing `"position"` caused severe visual defects: horizontal module groups (such as hardware monitors and audio controls) overflowed the bar width, text strings (network bandwidth, window titles) clipped or excessively widened the bar, and the clock could not fit cleanly in a standard narrow vertical dock (~48px).

Users need the ability to position Waybar on any screen edge (`top`, `bottom`, `left`, `right`) while keeping visual consistency, proper formatting, and full functionality.

## Decision

Split the Waybar configuration architecture into two distinct layout foundations, unified by an active root configuration and dynamic switcher script:

1. **`config-horizontal.jsonc` (Top & Bottom)**:
   - Sets `height: 44` (automatic full width).
   - Module groups maintain `"orientation": "horizontal"`.
   - Displays full horizontal window titles, horizontal time format (`{:%H:%M}`), and bandwidth rate stats.

2. **`config-vertical.jsonc` (Left & Right)**:
   - Sets `name: "vertical"` and `width: 50` (automatic full height).
   - Module groups switch to `"orientation": "vertical"`.
   - Window titles omitted in favor of clean vertical workspace pill stacks.
   - Strictly defines compact single-icon formats for all modules (including bluetooth, idle inhibitor, network link/disabled states, audio, hardware, and battery) to prevent any horizontal text overflow. Full metrics are preserved in detailed hover tooltips.
   - Stacked vertical clock format (`{:%H\n%M}`).

3. **`config.jsonc` Root Dispatcher**:
   - Acts as the entry point loaded by Waybar.
   - Specifies `name` (`horizontal` or `vertical`), the active edge (`position`), edge-specific margins, and includes the corresponding layout file.

4. **Interactive & CLI Switcher (`scripts/waybar-position.sh`)**:
   - Accepts `top`, `bottom`, `left`, or `right` as arguments.
   - Prompts via `wofi --dmenu` when run interactively without arguments.
   - Bound to key shortcut `SUPER + ALT + W` in Hyprland (`keybinds.lua`).
   - Automatically restarts Waybar to apply the changes smoothly.

5. **Responsive CSS Styles (`styles/modules.css`, `styles/workspaces.css`)**:
   - Leverages Waybar window class `window#waybar.vertical` (generated from `name: "vertical"`) along with position selectors to adjust pill padding (`padding: 6px 0`), zero out horizontal margins, and format vertical workspace buttons (`min-width: 32px`, `min-height: 28px`) without affecting horizontal layouts.

## Alternatives Considered

- **Single monolithic config**: Rejected because Waybar JSON does not support conditional expressions to alternate between `height` and `width` or switch group orientations based on position.
- **Four independent full configs**: Rejected as it would cause high configuration duplication between top/bottom and left/right. Grouping into horizontal and vertical profiles minimizes redundancy.
- **Dynamic template generator**: Unnecessary complexity and external dependencies compared to native Waybar JSON include directives.

## Consequences

- Users can seamlessly switch Waybar between all 4 screen positions via CLI or Wofi GUI.
- Horizontal and vertical orientations look native, balanced, and polished.
- Retains 100% Catppuccin Mocha theme consistency and existing custom module signals.

