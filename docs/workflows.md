# User Workflows Reference

This document describes how to execute daily tasks and interact with the desktop environment. It serves as a user manual and keyboard shortcut reference guide.

---

## Desktop Session Startup

When you log into the Hyprland session:
1. The background systems start (see [Architecture: Startup Sequence](architecture.md#startup-sequence)).
2. The network (`nm-applet`) and Bluetooth (`blueman-applet`) system trays start in the background.
3. The wallpaper is set by `wpaperd` (rotating a static image from `~/Pictures/wallpapers/` every 10 minutes).
4. The login hook starts `hyprsunset` by default. Change this in Hypr Dots Settings under Display.
5. The `waybar` panel renders at the saved edge (bottom by default). Press `SUPER + ALT + W` to choose an edge.

---

## Application Launching

Launch core programs using these shortcuts:

- **Terminal (Foot)**: Press `SUPER + Return`
- **File Manager (Thunar)**: Press `SUPER + E`
- **Application Launcher (Wofi)**: Press `SUPER + R`
- **Lock Screen (Hyprlock)**: Press `SUPER + Escape`

---

## Workspace Management

There are 10 primary workspaces, along with a dedicated scratchpad workspace.

- **Switch Workspaces**: Press `SUPER + [1-0]` (where `0` is Workspace 10).
- **Move Window to Workspace**: Press `SUPER + SHIFT + [1-0]`.
- **Scratchpad Toggle**: Press `SUPER + grave` (the `~` / \` key).
- **Move Window to Scratchpad**: Press `SUPER + SHIFT + grave`.
- **Move Window Out of Scratchpad**: Press `SUPER + CTRL + grave` (places it back on the active workspace).
- **Cycle Workspaces via Mouse**: Hold `SUPER` and scroll the mouse wheel up or down.

---

## Window Management

The default compositor layout is **Master** (the left screen holds a large master window, and the right holds a stack of other windows).

### Focus & Layout Controls
- **Move Focus**: Press `SUPER + [H/J/K/L]` (Vim-style navigation: Left, Down, Up, Right).
- **Move Window Position**: Press `SUPER + SHIFT + [H/J/K/L]`.
- To resize a floating window, left-drag an edge or corner when the resize cursor appears. You can also hold Super and right-drag inside the window, or press `SUPER + CTRL + [H/J/K/L]`.
- **Close Window**: Press `SUPER + C`.
- **Toggle Floating State**: Press `SUPER + SHIFT + C`.
- **Toggle Fullscreen (Active Window)**: Press `SUPER + F`.
- **Toggle Maximized (preserves gaps and bar space)**: Press `SUPER + SHIFT + F`.

### Switching Layouts
- **Dwindle Layout**: Press `SUPER + D`.
- **Master Layout**: Press `SUPER + M`.
- **Toggle Split Direction (Dwindle)**: Press `SUPER + S`.
- **Toggle Pseudo-tiling**: Press `SUPER + P`.

### Window Groups
Group multiple windows into a single tabbed container:
- **Create/Join Group**: Press `SUPER + G`.
- **Cycle Active Window in Group**: Press `SUPER + Tab`.
- **Move Window Out of Group**: Press `SUPER + SHIFT + G`.

### Opacity Control (Submap)
To dynamically change window transparency:
1. Press `SUPER + O` to enter the **opacity submap**.
2. Press any digit `[1-9]` to set opacity from `10%` to `90%`, or press `0` for `100%` opacity.
3. The submap automatically exits after you press a digit.
4. If you wish to cancel without changing opacity, press `Escape`.

---

## Mouse-Free Cursor Control (Submap)

If you do not have a physical mouse or touchpad, you can control the cursor entirely via the keyboard using the `ydotool` driver integration.

1. Enable the commented mouse submap and its entry binding first. Choose a free shortcut because Super+M selects the master layout.
2. All standard hotkeys are disabled until you exit this submap.
3. Use the keys below to control the mouse:

| Action | Normal Key | Fast Key (Hold Shift) | Description |
| :--- | :--- | :--- | :--- |
| **Move Cursor** | `h` / `j` / `k` / `l` | `H` / `J` / `K` / `L` | Vim-style cursor movement. |
| **Left Click** | `Spacebar` | — | Simulates left button tap. |
| **Right Click** | `Enter` | — | Simulates right button tap. |
| **Mouse Drag** | `v` (press) / `y` (release) | — | Press `v` to hold down click, move cursor, press `y` to drop. |
| **Scroll Vertical** | `u` (up) / `d` (down) | `up arrow` / `down arrow` (fast) | Scrolls windows vertically. |
| **Scroll Horizontal**| `left arrow` / `right arrow` | — | Scrolls windows horizontally. |
| **Exit Mouse Mode** | `Escape` | — | Returns keybindings back to normal. |

> [!WARNING]
> If `ydotool` commands fail, check that the user daemon is running:
> `systemctl --user status ydotool`

---

## Media & System Controls

Audio volume and panel brightness are adjusted using standard hardware media keys:

- **Raise Volume**: Press `XF86AudioRaiseVolume` (Volume increases by 5%).
- **Lower Volume**: Press `XF86AudioLowerVolume` (Volume decreases by 5%).
- **Mute Audio Output**: Press `XF86AudioMute`.
- **Mute Microphone Input**: Press `XF86AudioMicMute`.
- **Screen Brightness**: Press `XF86MonBrightnessUp` / `XF86MonBrightnessDown` (Adjusts by 5%).
- **Media Playback**: Press `XF86AudioPlay`, `XF86AudioPause`, `XF86AudioNext`, or `XF86AudioPrev`.

---

## Clipboard History

Text snippets and image captures are tracked automatically.

- **Open History Picker**: Press `SUPER + V` to show a list of copied items inside a `wofi` selector. Use arrow keys to select, and press `Enter` to copy it back to the clipboard.
- **Wipe Clipboard History**: Press `SUPER + SHIFT + V` to clear stored history.

---

## Night Mode & Do Not Disturb

Click the Waybar gear and open **Display → Night light**. **Night light now** controls the running schedule. **Start enabled at login** controls future sessions.

Use **Settings → Sound & notifications → Do Not Disturb** to silence Mako notifications. Under **Display → Screen**, turn on **Keep awake** to pause automatic locking, screen-off and idle suspend. You can close Settings and reopen it to turn Keep awake off. This switch resets when the session ends.

---

## Screen Capture

### Record video

Open the Waybar gear and go to **Display → Screen recording**. **Save recordings to** opens a folder picker. The default is your XDG Videos folder or `~/Videos`. To enter a path in the picker, press Ctrl+L.

Choose a capture area, turn on **Include audio** if wanted, then click **Start recording**.

| Capture area | What gets recorded |
|---|---|
| This monitor | The display containing Settings, including workspace switches on that display. |
| Select a region | A rectangle you drag within one monitor. Press Escape to cancel selection. |
| Choose a workspace or window | Select an existing workspace or an individual window in Hyprland’s sharing dialog, or dismiss it to cancel. A workspace capture stays with that workspace when you switch away. Optional audio captures the default sound output across workspaces. |

You can close Settings while recording. Reopen it with the gear and click **Stop recording** to finish the MP4. Settings shows the saved path. The folder is remembered for the next session.

### Take a screenshot

Shortcuts capture image files to `~/Pictures/`:

- **Full Screen Capture**: Press `Print`. Saves to file and triggers a system notification.
- **Region Screen Capture (Save & Copy)**: Press `SUPER + Print`. Use the cursor to drag a bounding box. Saves the file to disk, copies the image to clipboard, and sends a notification.
- **Region Screen Capture (Clipboard Only)**: Press `SUPER + SHIFT + S`. Drag a bounding box. Copies the image to clipboard without saving a file to disk.

---

## Wallpapers & Live Wallpaper Toggle

By default, static wallpapers rotate from `~/Pictures/wallpapers/`.

### Live Video Wallpaper
You can toggle a loop of the live video wallpaper (`~/Pictures/live-wallpapers/stone-bridge.mp4`):
- **Toggle On/Off**: Press `SUPER + W` to toggle `mpvpaper` on or off.
- **Behavior**: When active, the static wallpaper daemon `wpaperd` is covered by the video window. When toggled off, your static background rotation is restored.

---

## Lock & Power Sessions

- **Lock Screen**: Press `SUPER + Escape` to run `hyprlock`. Displays time, date, username, and an invisible password prompt.
- **Power Menu**: Click the red power button icon on the right side of Waybar to trigger the system shutdown/restart/logout power menu (requires `wlogout`).
- **Inactivity timeouts (Hypridle)**:
  - 5 minutes: Screen locks (`hyprlock`).
  - 10 minutes: Backlight turns off and keyboard lights turn off.
  - 11 minutes: System enters low-power suspend.
