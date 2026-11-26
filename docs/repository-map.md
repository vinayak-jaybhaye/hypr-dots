# Repository Map

This document provides a complete file-by-file directory reference for the `hypr-dots` repository, detailing the purpose, owner component, and safe modification guidelines for each file.

---

## Root Directory

The root directory contains repository setup scripts, package lists, and metadata.

### Setup Scripts

#### [bootstrap.sh](../bootstrap.sh)
- **Purpose**: Main entry point for setting up the environment. Runs the package installation script followed by the symlink script.
- **Owner**: Installation System.
- **Modification**: Only edit if changing the boot order or adding post-bootstrap steps.

#### [install-packages.sh](../install-packages.sh)
- **Purpose**: Installs system packages listed in `pkglist.txt` via `pacman`. Supports interactive (asking before installing) and auto-install modes.
- **Owner**: Installation System.
- **Modification**: Safe to edit if changing the installation prompts, logging, or error-handling behaviour.

#### [link-configs.sh](../link-configs.sh)
- **Purpose**: Symlinks configurations from the repository's `config/` directory under `XDG_CONFIG_HOME` (default `~/.config/`). Conflicts are skipped unless forced.
- **Owner**: Symlink & Deployment System.
- **Modification**: High risk. Ensure symlinking logic is robust. Test conflict and backup behavior in a temporary home.

#### [pkglist.txt](../pkglist.txt)
- **Purpose**: Flat text list of official Arch packages required by the desktop environment.
- **Owner**: Package Management.
- **Modification**: Add packages here if adding core components of the environment.

#### [aur-pkglist.txt](../aur-pkglist.txt)
- **Purpose**: Flat text list of AUR packages required by the desktop environment.
- **Owner**: Package Management.
- **Modification**: Add AUR packages here if they are not available in the official Arch repositories and require an AUR helper (e.g. yay or paru).

The compatibility name `pkglist.yay.txt` links to `aur-pkglist.txt`. Edit the AUR manifest once for both names.

#### [.gitignore](../.gitignore)
- **Purpose**: Git ignore rules for editor settings and temporary files.
- **Owner**: Repository Management.
- **Modification**: Add local development or IDE paths here.

---

## Config Directory (`config/`)

Shared application configuration lives here. The linker exposes it alongside selected theme files through per-user directories under `hypr-dots-theme/apps/`.

### Hyprland Composition (`config/hypr/`)

#### [hyprland.lua](../config/hypr/hyprland.lua)
- **Purpose**: Main compositor settings (monitors, scaling, input behavior, animations, decoration). Loads modular Lua files via `require()`.
- **Owner**: Hyprland Compositor.
- **Modification**: Safe to modify display scaling, mouse speeds, or workspace mappings.

#### [programs.lua](../config/hypr/programs.lua)
- **Purpose**: Default application preferences (`terminal`, `fileManager`, `menu`). Exported as a table for use across modules.
- **Owner**: Desktop Environment.
- **Modification**: Change default terminal or launcher here.

#### [exec.lua](../config/hypr/exec.lua)
- **Purpose**: Autostart commands executed on session start using `hl.on("hyprland.start")` (authentication agents, bars, system trays, clipboard managers).
- **Owner**: Session Startup.
- **Modification**: Add background services here using `hl.exec_cmd("<command>")`. Avoid running heavy GUI programs here.

#### [keybinds.lua](../config/hypr/keybinds.lua)
- **Purpose**: All keyboard shortcuts, dispatchers, and submaps (opacity, cursor simulation).
- **Owner**: Keyboard & User Input.
- **Modification**: High risk. When editing submaps (e.g. Opacity or Mouse simulation), always verify there is a corresponding `hl.dsp.submap("reset")` sequence to prevent locking user inputs.

#### [windowrules.lua](../config/hypr/windowrules.lua)
- **Purpose**: Window matching rules using `hl.window_rule` for resizing, floating, or assigning applications.
- **Owner**: Window Management.
- **Modification**: Add custom window matching rules using the `hl.window_rule` table syntax.

#### [legacy/](../config/hypr/legacy/)
- **Purpose**: Preserved backup of original Hyprlang `.conf` files (`hyprland.conf`, `exec.conf`, `keybinds.conf`, `windowrules.conf`) prior to native Lua migration.
- **Owner**: Migration Backup.
- **Modification**: Read-only historical reference.

#### [hypridle.conf](../config/hypr/hypridle.conf)
- **Purpose**: Idle management timeouts. Triggers screen dimming, lock, monitor power off, and system suspend.
- **Owner**: Power Management.
- **Modification**: Adjust timer lengths (`timeout` fields) to change lock times.

#### [hyprlock.conf](../config/hypr/hyprlock.conf)
- **Purpose**: Layout, styling, and text rendering rules for the lock screen.
- **Owner**: Session Locker.
- **Modification**: Edit widget sizes and positions here. Set fonts, colors and artwork in the theme.

#### [hyprsunset.conf](../config/hypr/hyprsunset.conf)
- **Purpose**: Blue-light filter profile settings (target temperature, daytime timings).
- **Owner**: Night Mode.
- **Modification**: Adjust target color temperature or gamma profile.

#### [hyprpaper.conf](../config/hypr/hyprpaper.conf)
- **Purpose**: Static wallpaper configurations. (Disabled/unused in favor of `wpaperd`).
- **Owner**: Wallpaper System (Legacy).
- **Modification**: Safe to modify, but has no effect unless enabled in `exec.lua`.

---

### Terminal Configuration

[foot.ini](../config/foot/foot.ini) configures the default terminal. Kitty is also configured for the Waybar network action.

#### [kitty.conf](../config/kitty/kitty.conf)
- **Purpose**: Kitty scrollback limits, padding, shell and cursor behavior.
- **Owner**: Kitty Terminal.
- **Modification**: Edit terminal fonts and opacity in a theme manifest.

---

### Notification Configuration (`config/mako/`)

#### [config](../config/mako/config)
- **Purpose**: Desktop notifications layout and timeouts, with urgency colors and a DND mode.
- **Owner**: Notifications.
- **Modification**: Adjust notification timeouts here and themed borders and fonts in the manifest.

---

### Wallpaper Daemon (`config/wpaperd/`)

#### [config.toml](../config/wpaperd/config.toml)
- **Purpose**: Configures rotation duration (10 min) and source directories for screen backgrounds.
- **Owner**: Wallpaper System.
- **Modification**: Set target monitor or wallpaper change intervals here.

---

### Launcher Configuration (`config/wofi/`)

#### [config](../config/wofi/config)
- **Purpose**: Window layout, dimensions, icons, search prompt, and general parameters for the Wofi application launcher.
- **Owner**: Application Launcher.
- **Modification**: Modify default window sizing, search prompt text, or display mode settings.

#### [style.css](../config/wofi/style.css)
- **Purpose**: Stylesheet for the Wofi search window using a glassmorphic Catppuccin Mocha theme.
- **Owner**: Application Launcher Styling.
- **Modification**: Modify colors, borders, focus box shadows, or selection list styles.

---

### Waybar Configuration (`config/waybar/`)


#### [config.jsonc](../config/waybar/config.jsonc)
- **Purpose**: Root Waybar configuration; sets active position (`top`, `bottom`, `left`, `right`), margins, and includes the corresponding layout config.
- **Owner**: Status Bar.
- **Modification**: Edit the project default here. The switcher stores user choices separately.

#### [config-horizontal.jsonc](../config/waybar/config-horizontal.jsonc)
- **Purpose**: Shared horizontal bar configuration for `top` and `bottom` positions.
- **Owner**: Status Bar Horizontal Layout.
- **Modification**: Adjust horizontal bar height, horizontal modules, or module groups.

#### [config-vertical.jsonc](../config/waybar/config-vertical.jsonc)
- **Purpose**: Shared vertical bar configuration for `left` and `right` positions.
- **Owner**: Status Bar Vertical Layout.
- **Modification**: Adjust vertical bar width, vertical modules, stacked clock, or compact status formats.

#### [style.css](../config/waybar/style.css)
- **Purpose**: Master stylesheet imports. Only contains `@import` rules.
- **Owner**: Status Bar Styling.
- **Modification**: Do not add raw styles here; only use it for imports.

#### Modules (`config/waybar/modules/`)
- [left.jsonc](../config/waybar/modules/left.jsonc): Defines components on the left (workspaces, active window title).
- [center.jsonc](../config/waybar/modules/center.jsonc) configures the clock and its calendar.
- [right.jsonc](../config/waybar/modules/right.jsonc): Declares the layout ordering of system widgets on the right.
- [system.jsonc](../config/waybar/modules/system.jsonc): Configuration details for all standard system widgets (battery, disk, CPU, memory).
- [custom.jsonc](../config/waybar/modules/custom.jsonc) defines the wattage readout, Settings gear and power menu.

#### Styles (`config/waybar/styles/`)
- [base.css](../config/waybar/styles/base.css): Global widget, tooltip and bar rules using the selected palette.
- [modules.css](../config/waybar/styles/modules.css): Colors, borders, margins, and hover effects for each status bar item.
- [states.css](../config/waybar/styles/states.css): Specialized animations (warning blinks, mute icons) for modules.
- [workspaces.css](../config/waybar/styles/workspaces.css): Workspace indicator sizing and active state styles.

---

## Scripts Directory (`scripts/`)

Desktop helpers are also available through the relative link [config/hypr/scripts](../config/hypr/scripts).

[screenshot.sh](../scripts/screenshot.sh) implements the full-screen, region and clipboard bindings.

#### [hyprsunset-status.sh](../scripts/hyprsunset-status.sh)
- Reports the current night light state as JSON for custom integrations.
- **Owner**: Status Indicator.
- **Modification**: Customize returned text icons or tooltips.

#### [hyprsunset-toggle.sh](../scripts/hyprsunset-toggle.sh)
- Controls the session’s `hyprsunset` process for Settings and the login hook.
- **Owner**: User Command Action.
- Supports `on`, `off`, `toggle` and `status`.

#### [mako-dnd-status.sh](../scripts/mako-dnd-status.sh)
- **Purpose**: Queries notification DND state and outputs JSON for custom integrations.
- **Owner**: Status Indicator.
- **Modification**: Customize DND text icons.

#### [mako-dnd-toggle.sh](../scripts/mako-dnd-toggle.sh)
- **Purpose**: Toggles DND mode via `makoctl` for Settings.
- **Owner**: User Command Action.
- **Modification**: Change the notification mode controlled by Settings.

#### [mic.sh](../scripts/mic.sh)
- **Purpose**: Resolves default microphone capture state and outputs active/muted JSON.
- **Owner**: Status Indicator.
- **Modification**: Customize microphone status icon formatting.

#### [power.sh](../scripts/power.sh)
- **Purpose**: Reads battery draw details using `upower` and displays wattage rate (charging/discharging).
- **Owner**: Status Indicator.
- **Modification**: Adjust battery polling formatting.

#### [livewall.sh](../scripts/livewall.sh)
- **Purpose**: Launches `mpvpaper` with low-latency hardware-accelerated video rendering.
- **Owner**: Desktop Wallpaper.
- **Modification**: Update the target output display or target video path.

#### [toggle-livewall.sh](../scripts/toggle-livewall.sh)
- **Purpose**: Toggles the running state of `mpvpaper` live wallpaper.
- **Owner**: User Command Action.
- **Modification**: Safe to modify if adding audio toggles or fallback screens.

#### [waybar-position.sh](../scripts/waybar-position.sh)
- **Purpose**: Switches Waybar position between `top`, `bottom`, `left`, and `right`, saving the selection under XDG state and reloading the matching layout. Its `--start` mode launches the bar at login.
- **Owner**: Status Bar Management.
- **Modification**: Add custom margin presets, menu prompts, or notification triggers.

## Themes

- [Theme guide](theming.md) and [decision 0012](decisions/0012-desktop-themes.md) describe the interface and deployment.
- [scripts/theme.py](../scripts/theme.py) discovers, validates, builds, publishes and reloads themes.
- [config/hypr/theme.lua](../config/hypr/theme.lua) loads the selected native Lua appearance.
- [themes/defaults.toml](../themes/defaults.toml) holds shared style values. The `catppuccin-mocha`, `fjord` and `dune` directories each contain a palette manifest. The latter two also contain a PNG wallpaper.
- [themes/templates/](../themes/templates/) contains adapters for Hyprland, Hyprlock, Waybar CSS and calendar markup, Wofi, Foot, Kitty and Mako. Wpaperd's template stays with its native rotation settings in `config/wpaperd/config.toml`.

## Desktop settings

- [settings.py](../scripts/settings.py) builds the three GTK pages, reads the visible controls and routes user actions.
- [recording.py](../scripts/recording.py) provides the Display page's folder picker and capture controls, owns the recorder and finalizes its MP4. [Recording lifecycle](decisions/0014-screen-recording.md) · [Workspace and window capture](decisions/0015-portal-recording.md)
- [desktop_controls.py](../scripts/desktop_controls.py) reads desktop values and saves the login preference. Its `login` entry point starts night light when enabled.
- [Desktop launcher](../scripts/io.github.hyprdots.Settings.desktop) exposes the window in Wofi and other application menus.
- [Decision 0013](decisions/0013-desktop-settings.md) records each setting's owner and lifetime.

## Regression tests

[tests/settings.py](../tests/settings.py) covers preference recovery, native state readers, session-scoped night light control and optional GTK interactions.

[tests/themes.py](../tests/themes.py) covers discovery, native configs, persistence, asset validation, invalid selections, overrides, concurrent publication and recovery.

[tests/deployment.sh](../tests/deployment.sh) exercises bootstrap, conflict backups, repeated linking and Waybar position changes from a renamed checkout in a disposable home.
