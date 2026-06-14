# Repository Map

This document provides a complete file-by-file directory reference for the `hypr-dots` repository, detailing the purpose, owner component, and safe modification guidelines for each file.

---

## Root Directory

The root directory contains repository setup scripts, package lists, and metadata.

### Setup Scripts

#### [bootstrap.sh](file:///home/phantom/hypr-dots/bootstrap.sh)
- **Purpose**: Main entry point for setting up the environment. Runs the package installation script followed by the symlink script.
- **Owner**: Installation System.
- **Modification**: Only edit if changing the boot order or adding post-bootstrap steps.

#### [install-packages.sh](file:///home/phantom/hypr-dots/install-packages.sh)
- **Purpose**: Installs system packages listed in `pkglist.txt` via `pacman`. Supports interactive (asking before installing) and auto-install modes.
- **Owner**: Installation System.
- **Modification**: Safe to edit if changing the installation prompts, logging, or error-handling behaviour.

#### [link-configs.sh](file:///home/phantom/hypr-dots/link-configs.sh)
- **Purpose**: Symlinks configurations from the repository's `config/` directory into `~/.config/`. Backs up existing files by default.
- **Owner**: Symlink & Deployment System.
- **Modification**: High risk. Ensure symlinking logic is robust. Test changes using the `--no-backup` or `--force` flags.

#### [pkglist.txt](file:///home/phantom/hypr-dots/pkglist.txt)
- **Purpose**: Flat text list of official Arch packages required by the desktop environment.
- **Owner**: Package Management.
- **Modification**: Add packages here if adding core components of the environment.

#### [aur-pkglist.txt](file:///home/phantom/hypr-dots/aur-pkglist.txt)
- **Purpose**: Flat text list of AUR packages required by the desktop environment.
- **Owner**: Package Management.
- **Modification**: Add AUR packages here if they are not available in the official Arch repositories and require an AUR helper (e.g. yay or paru).

---

## Config Directory (`config/`)

All program configurations reside under the `config/` directory, which gets mapped directly to `~/.config/`.

### Hyprland Composition (`config/hypr/`)

#### [hyprland.conf](file:///home/phantom/hypr-dots/config/hypr/hyprland.conf)
- **Purpose**: Main compositor settings (monitors, scaling, input behavior, basic decoration). Sources helper configuration files at the bottom.
- **Owner**: Hyprland Compositor.
- **Modification**: Safe to modify display scaling, mouse speeds, or workspace mappings. Do NOT move the source lines at the bottom.

#### [exec.conf](file:///home/phantom/hypr-dots/config/hypr/exec.conf)
- **Purpose**: Commands executed once at start (authentication agents, bars, system trays, clipboard managers).
- **Owner**: Session Startup.
- **Modification**: Add background services here using `exec-once = <command>`. Avoid running heavy GUI programs here.

#### [keybinds.conf](file:///home/phantom/hypr-dots/config/hypr/keybinds.conf)
- **Purpose**: All keyboard shortcuts and cursor simulation submaps.
- **Owner**: Keyboard & User Input.
- **Modification**: High risk. When editing submaps (e.g. Opacity or Mouse simulation), always verify there is a corresponding `submap = reset` sequence to prevent locking user inputs.

#### [windowrules.conf](file:///home/phantom/hypr-dots/config/hypr/windowrules.conf)
- **Purpose**: Specific rules for resizing, floating, or assigning applications to workspaces. (Currently empty placeholder).
- **Owner**: Window Management.
- **Modification**: Add custom window matching rules using the Hyprland v2 layout: `windowrulev2 = rule, match`.

#### [hypridle.conf](file:///home/phantom/hypr-dots/config/hypr/hypridle.conf)
- **Purpose**: Idle management timeouts. Triggers screen dimming, lock, monitor power off, and system suspend.
- **Owner**: Power Management.
- **Modification**: Adjust timer lengths (`timeout` fields) to change lock times.

#### [hyprlock.conf](file:///home/phantom/hypr-dots/config/hypr/hyprlock.conf)
- **Purpose**: Layout, styling, and text rendering rules for the lock screen.
- **Owner**: Session Locker.
- **Modification**: Change background image path, color variables, font sizes, or input field dimensions here.

#### [hyprsunset.conf](file:///home/phantom/hypr-dots/config/hypr/hyprsunset.conf)
- **Purpose**: Blue-light filter profile settings (target temperature, daytime timings).
- **Owner**: Night Mode.
- **Modification**: Adjust target color temperature or gamma profile.

#### [hyprpaper.conf](file:///home/phantom/hypr-dots/config/hypr/hyprpaper.conf)
- **Purpose**: Static wallpaper configurations. (Disabled/unused in favor of `wpaperd`).
- **Owner**: Wallpaper System (Legacy).
- **Modification**: Safe to modify, but has no effect unless enabled in `exec.conf`.

---

### Terminal Configuration (`config/kitty/`)

#### [kitty.conf](file:///home/phantom/hypr-dots/config/kitty/kitty.conf)
- **Purpose**: Kitty terminal font, terminal history scrollback limits, window margins, and Catppuccin color declarations.
- **Owner**: Kitty Terminal.
- **Modification**: Modify default font size, terminal opacity (`background_opacity`), or key bindings.

---

### Notification Configuration (`config/mako/`)

#### [config](file:///home/phantom/hypr-dots/config/mako/config)
- **Purpose**: Desktop notifications layout and timeouts. (Empty — uses Mako defaults).
- **Owner**: Notifications.
- **Modification**: Modify default notification timeout, border width, or fonts.

---

### Wallpaper Daemon (`config/wpaperd/`)

#### [config.toml](file:///home/phantom/hypr-dots/config/wpaperd/config.toml)
- **Purpose**: Configures rotation duration (10 min) and source directories for screen backgrounds.
- **Owner**: Wallpaper System.
- **Modification**: Set target monitor or wallpaper change intervals here.

---

### Waybar Configuration (`config/waybar/`)

#### [config.jsonc](file:///home/phantom/hypr-dots/config/waybar/config.jsonc)
- **Purpose**: Main Waybar layout configuration; lists modular includes.
- **Owner**: Status Bar.
- **Modification**: Edit to change bar margins, height, or global spacing.

#### [style.css](file:///home/phantom/hypr-dots/config/waybar/style.css)
- **Purpose**: Master stylesheet imports. Only contains `@import` rules.
- **Owner**: Status Bar Styling.
- **Modification**: Do not add raw styles here; only use it for imports.

#### Modules (`config/waybar/modules/`)
- [left.jsonc](file:///home/phantom/hypr-dots/config/waybar/modules/left.jsonc): Defines components on the left (workspaces, active window title).
- [center.jsonc](file:///home/phantom/hypr-dots/config/waybar/modules/center.jsonc): Defines components in the center (clock, custom night mode, custom DND).
- [right.jsonc](file:///home/phantom/hypr-dots/config/waybar/modules/right.jsonc): Declares the layout ordering of system widgets on the right.
- [system.jsonc](file:///home/phantom/hypr-dots/config/waybar/modules/system.jsonc): Configuration details for all standard system widgets (battery, disk, CPU, memory).
- [custom.jsonc](file:///home/phantom/hypr-dots/config/waybar/modules/custom.jsonc): Configuration details for custom scripts (power menus, microphone toggle status, night mode indicator).

#### Styles (`config/waybar/styles/`)
- [base.css](file:///home/phantom/hypr-dots/config/waybar/styles/base.css): Global rules and Catppuccin Mocha color variable definitions.
- [modules.css](file:///home/phantom/hypr-dots/config/waybar/styles/modules.css): Colors, borders, margins, and hover effects for each status bar item.
- [states.css](file:///home/phantom/hypr-dots/config/waybar/styles/states.css): Specialized animations (warning blinks, mute icons) for modules.
- [workspaces.css](file:///home/phantom/hypr-dots/config/waybar/styles/workspaces.css): Workspace indicator sizing and active state styles.

---

## Scripts Directory (`scripts/`)

Helper scripts used for status outputs, toggle actions, or live wallpapers.

#### [hyprsunset-status.sh](file:///home/phantom/hypr-dots/scripts/hyprsunset-status.sh)
- **Purpose**: Checks if `hyprsunset` is active and outputs JSON for the Waybar custom night-mode module.
- **Owner**: Status Indicator.
- **Modification**: Customize returned text icons or tooltips.

#### [hyprsunset-toggle.sh](file:///home/phantom/hypr-dots/scripts/hyprsunset-toggle.sh)
- **Purpose**: Toggles `hyprsunset` daemon and triggers a Waybar custom module update signal (`RTMIN+2`).
- **Owner**: User Command Action.
- **Modification**: Modify execution logic or change signal numbers.

#### [mako-dnd-status.sh](file:///home/phantom/hypr-dots/scripts/mako-dnd-status.sh)
- **Purpose**: Queries notification DND state and outputs JSON for Waybar.
- **Owner**: Status Indicator.
- **Modification**: Customize DND text icons.

#### [mako-dnd-toggle.sh](file:///home/phantom/hypr-dots/scripts/mako-dnd-toggle.sh)
- **Purpose**: Toggles DND mode via `makoctl` and signals Waybar (`RTMIN+3`).
- **Owner**: User Command Action.
- **Modification**: Change notification modes or signal number.

#### [mic.sh](file:///home/phantom/hypr-dots/scripts/mic.sh)
- **Purpose**: Resolves default microphone capture state and outputs active/muted JSON.
- **Owner**: Status Indicator.
- **Modification**: Customize microphone status icon formatting.

#### [power.sh](file:///home/phantom/hypr-dots/scripts/power.sh)
- **Purpose**: Reads battery draw details using `upower` and displays wattage rate (charging/discharging).
- **Owner**: Status Indicator.
- **Modification**: Adjust battery polling formatting.

#### [livewall.sh](file:///home/phantom/hypr-dots/scripts/livewall.sh)
- **Purpose**: Launches `mpvpaper` with low-latency hardware-accelerated video rendering.
- **Owner**: Desktop Wallpaper.
- **Modification**: Update the target output display or target video path.

#### [toggle-livewall.sh](file:///home/phantom/hypr-dots/scripts/toggle-livewall.sh)
- **Purpose**: Toggles the running state of `mpvpaper` live wallpaper.
- **Owner**: User Command Action.
- **Modification**: Safe to modify if adding audio toggles or fallback screens.
