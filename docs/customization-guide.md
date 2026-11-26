# Customization Guide

How to personalize every aspect of this Hyprland desktop environment.

---

## Theme, colors and fonts

Set palette roles, fonts, opacity, rounding and borders in a theme manifest. Shared GTK styles still control widget geometry and interaction states. Use a Nerd Font for the bar's icon glyphs. The [theme guide](theming.md) covers switching, component overrides and artwork.

## Keybindings

**File:** `config/hypr/keybinds.lua`

Add bindings to the matching section. A dispatcher describes an action and a Lua callback can sequence several actions.

```lua
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("firefox"))
```

The optional third argument sets options such as `mouse`, `locked` and `repeating`. Put a reset binding in every submap so Escape always returns to the normal keys.

```lua
hl.bind(mainMod .. " + X", hl.dsp.submap("mymode"))
hl.define_submap("mymode", function()
    hl.bind("escape", hl.dsp.submap("reset"))
end)
```

Super+O opens the opacity submap. The mouse submap is commented out. Choose a free entry key if you enable it, since Super+M already selects master layout.

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

The theme controls `rounding`, `border_width` and inactive `window_opacity`. Adjust focus dimming and active opacity in the compositor's `decoration` table.

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

Add commands to the existing `hl.on("hyprland.start", function() ... end)` block in `exec.lua`. For example, add `hl.exec_cmd("firefox")` inside that callback to launch Firefox once on login.

## Waybar

The default edge is in `config/waybar/config.jsonc`. The position menu (Super+Alt+W) stores your choice in `${XDG_STATE_HOME:-$HOME/.local/state}/hypr-dots/waybar-position.jsonc`. Each edge selects `config-horizontal.jsonc` or `config-vertical.jsonc`. Both layouts include the files in `modules/`. Put shared actions and module settings there, and add overrides to the vertical profile for compact formatting.

Top and bottom show the weekday, date and time together. Left and right stack hours over minutes and show the remaining charge beneath the battery icon. The blue marker on the active workspace faces the windows on each edge. Hover over the network icon on any edge for the address and current transfer rates.

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

Module order is controlled by the arrays in `modules/left.jsonc`, `modules/center.jsonc`, and `modules/right.jsonc`. Reorder the module names in the array. Set a group’s `orientation` to `inherit` so it follows the bar when you switch edges. Waybar exposes `group/audio` to GTK as `#audio`.

### Styling

CSS is split into four files imported by `style.css`:

| File | Purpose |
|---|---|
| `styles/base.css` | Global widget rules and bar/tooltip styling |
| `styles/modules.css` | Module colors, padding, hover effects |
| `styles/states.css` | State-specific styles (battery warning, muted, etc.) |
| `styles/workspaces.css` | Workspace button styles |

### Custom modules (script-based)

Custom modules use scripts with real-time signal-based updates:

```jsonc
"custom/mymodule": {
  "exec": "\"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/my-status.sh\"",
  "return-type": "json",
  "on-click": "\"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/my-toggle.sh\"",
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

The shipped modules use no real-time refresh signals.

---

## Launcher (Wofi)

Wofi reads `config/wofi/config` for dimensions, search and icon settings, and `config/wofi/style.css` for the launcher theme. Its launch command lives in `config/hypr/programs.lua`.

---

## Wallpaper

### Static wallpaper (wpaperd)

**File:** `config/wpaperd/config.toml`

```toml
[any]
path = "{{wallpaper_path}}"
duration = "10m"
```

- Rotates through the selected theme’s images every 10 minutes. Mocha uses `~/Pictures/wallpapers/`
- Applies to outputs without a more specific section
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

1. Install `hyprpaper` and uncomment `hl.exec_cmd("hyprpaper")` in `exec.lua`
2. Comment out `hl.exec_cmd("wpaperd")`
3. Configure `hyprpaper.conf` with your wallpaper path

### Live wallpaper (mpvpaper)

**File:** `scripts/livewall.sh`

Toggle with `SUPER+W`. Uses `mpvpaper` to play a video file as the wallpaper:

```bash
VIDEO="$HOME/Pictures/live-wallpapers/stone-bridge.mp4"
```

Set `LIVEWALL_VIDEO` and optionally `LIVEWALL_OUTPUT` in the session environment to override the defaults. The video is played on loop, without audio, using hardware-accelerated decoding.

---

## Lock Screen (Hyprlock)

**File:** `config/hypr/hyprlock.conf`

### Layout

The lock screen displays:
- **Background:** selected lock image, defaulting to `~/Pictures/wallpapers/bg1.jpg` for Mocha (no blur)
- **Time:** centered, 72px font, positioned above center
- **Date:** centered, 24px font (updates every minute via `cmd[update:1000]`)
- **Username:** centered, 16px, below center
- **Password input:** invisible field (fully transparent border/background), centered

### Customizing

Set the theme’s optional `lockscreen` image in its manifest. Edit the shared background block to change blur.

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
| 300s (5 min) | Lock screen with `hyprlock` |
| 600s (10 min) | Turn off display (DPMS) + turn off keyboard backlight |
| 660s (11 min) | Suspend system |

### Customizing timeouts

```conf
listener {
  timeout = 300        # 5 minutes
  on-timeout = hyprlock
}
```

### Disabling idle temporarily

Open **Settings → Display → Keep awake** to pause idle actions for this session.

---

## Notifications (Mako)

Edit `config/mako/config` to change the top-right placement and urgency-specific timeouts. The DND mode hides incoming notifications until disabled.

### Do Not Disturb

Use **Settings → Sound & notifications → Do Not Disturb**. This switch calls `scripts/mako-dnd-toggle.sh`.
