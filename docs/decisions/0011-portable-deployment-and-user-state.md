# 0011 — Checkout-independent deployment and per-user Waybar state

## Context

The session launched helpers from a fixed checkout path. Waybar edge changes wrote through a deployed symlink into Git and sometimes copied over a separate user configuration. The vertical profile duplicated actions, refresh signals and sensor settings from the horizontal modules.

## Decision

Keep the public install commands at the repository root. Resolve sources from the checkout and link each native configuration directory under `XDG_CONFIG_HOME`. A relative link at `config/hypr/scripts` exposes the existing shared helper directory through the deployed configuration.

Start Waybar through `waybar-position.sh --start`. It loads the project default until an edge is selected. The switcher then atomically writes a small JSON file selecting a layout and its margins under `XDG_STATE_HOME/hypr-dots`. A running bar adopts that profile on its first switch and reloads it on subsequent switches. Both orientation files include the same module fragments. Vertical overrides express the differences in ordering, orientation, formatting and tooltips.

## Alternatives Considered

Copying helpers to a bin directory would require reinstalling after script edits. Generating complete Waybar profiles would duplicate the native include mechanism and make the effective configuration harder to review. A shared theme generator would add a build step for applications that already load their own palettes.

## Consequences

Existing app-directory symlinks pick up changes immediately. The checkout can be named freely, and each user's edge preference survives login. A standalone `waybar` invocation uses the repository default. Use the session launcher to load the saved preference. Removing the saved position file restores the project default at the next launch.
