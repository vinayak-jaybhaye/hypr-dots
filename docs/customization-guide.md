# Customization Guide

How to personalize every aspect of this Hyprland desktop environment.

---

## Theme & Colors

This setup uses the **Catppuccin Mocha** color palette throughout. Colors are defined in multiple places — change them all for a consistent look.

### Waybar (primary color definitions)

**File:** `config/waybar/styles/base.css`

All colors are defined as CSS variables with `@define-color`:

```css
@define-color base      #1e1e2e;
@define-color text      #cdd6f4;
@define-color blue      #89b4fa;
/* ... etc ... */
```

To switch to a different Catppuccin flavor (Latte, Frappé, Macchiato), replace the hex values in this file. See [catppuccin.com](https://catppuccin.com/) for the full palette.

Module-specific colors are in `config/waybar/styles/modules.css`:

```css
#clock      { color: @lavender; }
#network    { color: @teal; }
#battery    { color: @green; }
```

State-based colors (battery warning, muted audio, etc.) are in `config/waybar/styles/states.css`.

### Kitty terminal

**File:** `config/kitty/kitty.conf`

Colors are set as direct hex values (kitty doesn't use CSS variables):

```conf
foreground #cdd6f4
background #1e1e2e
cursor     #f5e0dc
color0     #45475a    # black (surface1)
color1     #f38ba8    # red
# ... colors 2-15 ...
```

Selection colors, tab bar colors, and cursor color are also set here.

### Hyprland borders

**File:** `config/hypr/hyprland.lua`, `general.col` table:

```lua
col = {
    active_border   = { colors = { "rgba(cba6f7ee)", "rgba(89b4faee)" }, angle = 45 },
    inactive_border = "rgba(313244aa)",
},
```

---

## Font

The font **JetBrainsMono Nerd Font** is used in three places:

| File | Setting |
|---|---|
| `config/kitty/kitty.conf` | `font_family JetBrains Mono` (line 6) |
| `config/waybar/styles/base.css` | `font-family: "JetBrainsMono Nerd Font"` (line 30) |
| `config/hypr/hyprlock.conf` | `font_family = JetBrainsMono Nerd Font` (labels and input field) |

To change the font, update all three locations. Ensure the Nerd Font variant is installed for icon glyphs in waybar and the terminal.

---

## Keybindings

**File:** `config/hypr/keybinds.lua`

### Structure

Keybinds are organized into clearly-labeled sections:

```
########################
### SECTION NAME #######
########################
```

Sections: Modifier, Launchers, Window Actions, Layout, Focus Movement, Window Movement, Resize, Window Opacity, Workspaces, Special Workspace, Clipboard, Screenshots, Mouse, Media/System, Custom.

### Adding a keybind

Add a new `bind` line to the appropriate section:

```conf
# Syntax: bind = MODIFIERS, KEY, DISPATCHER, ARGS
bind = $mainMod, N, exec, firefox
```

Common dispatchers:
- `exec` — run a command
- `killactive` — close focused window
- `workspace, N` — switch to workspace N
- `movetoworkspace, N` — move window to workspace N
- `togglefloating` — float/unfloat window
- `fullscreen, 0|1|2` — fullscreen modes

### Bind types

| Prefix | Behavior |
|---|---|
| `bind` | Standard keybind |
| `bindm` | Mouse button bind |
| `bindel` | Repeats while held + works on lock screen |
| `bindl` | Works on lock screen |

### Submaps

Submaps let you enter a mode where keys have different meanings. Two submaps are defined:

**Opacity submap** (`SUPER+O`):

```conf
bind = $mainMod, O, submap, opacity
submap = opacity
bind = , 1, exec, hyprctl dispatch setprop active opacity 0.1; hyprctl dispatch submap reset
# ... keys 2-9, 0 ...
bind = , escape, submap, reset
submap = reset
```

**Mouse submap** (`SUPER+M`):

```conf
bind = $mainMod, M, submap, mouse
submap = mouse
bind = , h, exec, ydotool mousemove -- -20 0
# ... movement, clicks, scroll ...
bind = , escape, submap, reset
submap = reset
```

> [!WARNING]
> `SUPER+M` is bound to **both** the mouse submap and the master layout switch. The submap bind (line 180) takes precedence since it appears later in the file. If you want both, change one of the keys.

### Adding a new submap

```conf
bind = $mainMod, X, submap, mymode
submap = mymode
# Define keys for this mode
bind = , a, exec, some-command
bind = , escape, submap, reset
submap = reset
```

---

## Animations

**File:** `config/hypr/hyprland.lua`, `hl.curve` and `hl.animation` calls

### Bezier curves

Five bezier curves are defined:

| Name | Control Points | Character |
|---|---|---|
| `easeOutQuint` | 0.23, 1, 0.32, 1 | Quick start, smooth stop |
| `easeInOutCubic` | 0.65, 0.05, 0.36, 1 | Smooth start and stop |
| `linear` | 0, 0, 1, 1 | Constant speed |
| `almostLinear` | 0.5, 0.5, 0.75, 1 | Slight ease-out |
| `quick` | 0.15, 0, 0.1, 1 | Snappy |

### Animation declarations

```lua
-- Syntax: hl.animation({ leaf = NAME, enabled = BOOLEAN, speed = NUMBER, bezier = CURVE [, style = STYLE] })
hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
```

Speed is in 100ms units (e.g., `4.79` = ~480ms). To disable an animation, set `enabled = false`.

### Adding a custom animation

```lua
-- Define a new bezier curve:
hl.curve("myBounce", { type = "bezier", points = { {0.68, -0.55}, {0.27, 1.55} } })

-- Use it:
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5, bezier = "myBounce", style = "slide" })
```

---

## Layout

**File:** `config/hypr/hyprland.lua`

### Default layout

The default layout is **master** (set in `general.layout`):

```lua
hl.config({
    general = {
        layout = "master",
    },
})
```

Toggle between layouts at runtime:
- `SUPER+M` — switch to master layout
- `SUPER+D` — switch to dwindle layout

### Gaps and borders

```lua
hl.config({
    general = {
        gaps_in = 4,       -- gap between windows
        gaps_out = 8,      -- gap between windows and screen edge
        border_size = 2,   -- window border thickness in pixels
    },
})
```

### Dwindle-specific settings

```lua
hl.config({
    dwindle = {
        preserve_split = true,   -- keep split direction when moving windows
    },
})
```

### Rounding and opacity

```lua
hl.config({
    decoration = {
        rounding = 10,           -- corner radius
        active_opacity = 1.0,    -- focused window opacity (1 = opaque)
        inactive_opacity = 0.90, -- unfocused window opacity
        dim_inactive = true,
        dim_strength = 0.12,
    },
})
```

---

## Window Rules

**File:** `config/hypr/windowrules.lua`

Defines per-application rules to keep dialogs and utilities properly floating.

### Adding window rules

```lua
-- Float and resize a specific app:
hl.window_rule({
    match = { class = "^(pavucontrol)$" },
    float = true,
    size = "800 600",
})

-- Make a window transparent:
hl.window_rule({
    match = { class = "^(kitty)$" },
    opacity = "0.9 0.8",
})

-- Send an app to a specific workspace:
hl.window_rule({
    match = { class = "^(firefox)$" },
    workspace = "2",
})

-- Disable blur for certain windows:
hl.window_rule({
    match = { class = "^(firefox)$" },
    no_blur = true,
})
```

Use `hyprctl clients` to find the `class` and `title` of running windows.

---

## Startup Applications

**File:** `config/hypr/exec.lua`

Current startup sequence using `hl.on("hyprland.start", function() ... end)`:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprsunset")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wpaperd")
end)
```
exec-once = hypridle               # idle manager
exec-once = wpaperd                # wallpaper daemon
```

### Adding a startup app

```conf
# Run once on login:
exec-once = firefox

# Run on every config reload:
exec = some-command
```

> [!NOTE]
> `exec-once` runs the command only at Hyprland startup. `exec` runs it every time the config is reloaded. Use `exec-once` for daemons and apps, `exec` for setting environment variables or one-shot setup.

---

## Waybar

### Config structure

The main config is `config/waybar/config.jsonc`. It sets bar properties and includes modular configs:

```jsonc
{
  "layer": "top",
  "position": "top",
  "height": 44,
  "include": [
    "modules/left.jsonc",     // workspaces, window title
    "modules/center.jsonc",   // clock, hyprsunset, dnd
    "modules/right.jsonc",    // module ordering
    "modules/system.jsonc",   // system module configs
    "modules/custom.jsonc"    // custom script modules
  ]
}
```

### Adding a module

1. Define the module in the appropriate module file (e.g., `modules/system.jsonc`):

```jsonc
"disk": {
  "interval": 30,
  "format": "󰋊 {percentage_used}%",
  "path": "/"
}
```

2. Add it to the module list in `modules/right.jsonc` (or left/center):

```jsonc
"modules-right": ["network", "disk", "battery", ...]
```

3. Style it in `styles/modules.css`:

```css
#disk {
  color: @sapphire;
}
```

Don't forget to add it to the shared selector block and hover block in `modules.css`.

### Module order

Module order is controlled by the arrays in `modules/left.jsonc`, `modules/center.jsonc`, and `modules/right.jsonc`. Simply reorder the module names in the array.

### Styling

CSS is split into four files imported by `style.css`:

| File | Purpose |
|---|---|
| `styles/base.css` | Color palette, fonts, bar/tooltip background |
| `styles/modules.css` | Module colors, padding, hover effects |
| `styles/states.css` | State-specific styles (battery warning, muted, etc.) |
| `styles/workspaces.css` | Workspace button styles |

### Custom modules (script-based)

Custom modules use scripts with real-time signal-based updates:

```jsonc
"custom/mymodule": {
  "exec": "~/hypr-dots/scripts/my-status.sh",
  "return-type": "json",
  "on-click": "~/hypr-dots/scripts/my-toggle.sh",
  "signal": 4              // update on RTMIN+4
}
```

The status script outputs JSON:

```json
{"text": "icon", "tooltip": "description", "class": "state"}
```

The toggle script sends the update signal after changing state:

```bash
pkill -RTMIN+4 waybar
```

Currently used signals: `RTMIN+2` (hyprsunset), `RTMIN+3` (DND).

---

## Launcher (Wofi)

**File:** none in this repo — wofi uses defaults.

Wofi is invoked as:

```conf
$menu = wofi --show drun
```

To customize wofi, create `~/.config/wofi/config` and `~/.config/wofi/style.css`:

```ini
# ~/.config/wofi/config
width=600
height=400
mode=drun
prompt=Search...
insensitive=true
```

```css
/* ~/.config/wofi/style.css */
window {
  background-color: #1e1e2e;
  border-radius: 12px;
  border: 1px solid #313244;
}
```

---

## Wallpaper

### Static wallpaper (wpaperd)

**File:** `config/wpaperd/config.toml`

```toml
[eDP-1]
path = "~/Pictures/wallpapers"
duration = "10m"
```

- Rotates through all images in `~/Pictures/wallpapers/` every 10 minutes
- Tied to monitor `eDP-1`
- Clicking the clock module in waybar triggers next/previous wallpaper (`wpaperctl next`/`wpaperctl previous`)

To change the rotation interval:

```toml
duration = "30m"    # 30 minutes
duration = "1h"     # 1 hour
duration = "0"      # disable rotation (static)
```

### Hyprpaper (disabled)

**File:** `config/hypr/hyprpaper.conf`

Hyprpaper is configured but commented out in `exec.lua`. It's kept as an alternative. To switch to hyprpaper:

1. Uncomment `hl.exec_cmd("hyprpaper")` in `exec.lua`
2. Comment out `hl.exec_cmd("wpaperd")`
3. Configure `hyprpaper.conf` with your wallpaper path

### Live wallpaper (mpvpaper)

**File:** `scripts/livewall.sh`

Toggle with `SUPER+W`. Uses `mpvpaper` to play a video file as the wallpaper:

```bash
VIDEO="$HOME/Pictures/live-wallpapers/stone-bridge.mp4"
```

To change the video, edit the `VIDEO` variable in `scripts/livewall.sh`. The video is played on loop, without audio, using hardware-accelerated decoding.

---

## Lock Screen (Hyprlock)

**File:** `config/hypr/hyprlock.conf`

### Layout

The lock screen displays:
- **Background:** `~/Pictures/wallpapers/bg1.jpg` (no blur)
- **Time:** centered, 72px font, positioned above center
- **Date:** centered, 24px font (updates every second via `cmd[update:1000]`)
- **Username:** centered, 16px, below center
- **Password input:** invisible field (fully transparent border/background), centered

### Customizing

Change the background image:

```conf
background {
  path = $HOME/Pictures/wallpapers/my-lock-bg.png
  blur_passes = 3    # enable blur
  blur_size = 8
}
```

Change label fonts, sizes, and positions:

```conf
label {
  text = $TIME
  font_family = Your Font Name
  font_size = 48
  position = 0, 100
}
```

Make the password input visible:

```conf
input-field {
  inner_color = rgba(30, 30, 46, 0.8)
  outer_color = rgba(137, 180, 250, 0.5)
  outline_thickness = 2
  rounding = 12
}
```

---

## Idle Behavior (Hypridle)

**File:** `config/hypr/hypridle.conf`

### Current sequence

| Timeout | Action |
|---|---|
| 600s (10 min) | Lock screen with `hyprlock` |
| 660s (11 min) | Turn off display (DPMS) + turn off keyboard backlight |
| 660s (11 min) | Suspend system |

### Customizing timeouts

```conf
listener {
  timeout = 300        # 5 minutes
  on-timeout = hyprlock
}
```

### Disabling idle temporarily

Click the idle inhibitor icon in waybar (coffee cup), or:

```bash
hyprctl dispatch dpms on
```

---

## Notifications (Mako)

**File:** `config/mako/config`

The mako config is currently **empty**, meaning mako uses all default settings:

- Position: top-right
- Default timeout: 5 seconds
- No custom styling

### Adding mako configuration

```ini
# Example mako config
font=JetBrainsMono Nerd Font 11
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-radius=8
border-size=2
padding=10
default-timeout=5000
width=350
max-visible=3

[urgency=critical]
background-color=#1e1e2e
text-color=#f38ba8
border-color=#f38ba8
default-timeout=0
```

### Do Not Disturb

DND is toggled via the waybar module or `~/hypr-dots/scripts/mako-dnd-toggle.sh`. It uses `makoctl mode -t do-not-disturb` to suppress notifications.
