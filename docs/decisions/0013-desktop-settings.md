# 0013 — A settings window over the existing desktop controls

## Context

The bar, keyboard shortcuts and theme CLI already manage several settings. Adding a window introduces a second way to change them. Volume keys can change the default sink's volume while the window is open, and stopping night light for this session has a different lifetime from choosing what starts at login.

## Decision

Give each value one owner. The settings window reuses the theme and edge switchers, queries the selected page's live controls periodically and sends explicit on/off requests through the same helpers as Waybar. Reads and writes run on a worker so the GTK main loop stays responsive. The process exits when the window closes.

| Value | Owner and lifetime |
|---|---|
| Current theme | The active theme generation's `theme-id` under `$XDG_CONFIG_HOME/hypr-dots-theme/current/`. The retained previous generation identifies the last theme when it differs. |
| Bar position | The saved Waybar profile under `$XDG_STATE_HOME/hypr-dots/waybar-position.jsonc`, falling back to the deployed default. |
| Night light at login | `$XDG_CONFIG_HOME/hypr-dots/preferences.json` stores `night_light_at_login`. A missing key defaults to true. The login hook consumes it once. |
| Night light now | The hyprsunset process for this user and Wayland display. Its native config supplies the temperature schedule. |
| Wallpaper, brightness, audio and notification mode | Wpaperd, the backlight device, WirePlumber and Mako each own their live values. |

New project preferences belong in the preferences file when a component lacks a suitable owner. Writes lock the directory's preference lock, preserve unknown keys and replace the file atomically. A malformed file is reported and preserved. Login uses the default in that case.

## Alternatives Considered

A database mirroring every control would need to reconcile hardware keys, other desktop tools, and direct CLI edits. A resident settings service would add startup and lifecycle handling to controls that already have working owners. GNOME's GSettings could store project preferences, but the single login option currently needs neither a compiled schema nor a backend service.

Omarchy stages the next theme and records the selected name under its configuration directory. HyDE saves the theme selection with its shared configuration helper and emits compositor theme state under the XDG state directory. Both informed our decision to keep using the existing theme switcher. [Omarchy theme switcher](https://github.com/basecamp/omarchy/blob/master/bin/omarchy-theme-set) · [HyDE theme switcher](https://github.com/HyDE-Project/HyDE/blob/master/Configs/.local/lib/hyde/theme.switch.sh)

## Consequences

Existing selections work on upgrade. A change from the bar or a shortcut appears the next time the window reads that page. An unavailable device or service disables its row and the tooltip shows the error. A new contributor can add a control by choosing its owner, implementing a read and an explicit write, then registering a row on the relevant page.
