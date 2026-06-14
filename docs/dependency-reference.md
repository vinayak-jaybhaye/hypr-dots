# Dependency Reference

Every dependency used by this Hyprland configuration, grouped by category.

> [!NOTE]
> Packages in the **"Automated Install"** column are installed automatically by `install-packages.sh`. Official packages are in `pkglist.txt` and AUR packages are in `aur-pkglist.txt`.

---

## Core (Hyprland Ecosystem)

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `hyprland` | Wayland compositor — the window manager itself | Everything | Yes | **Required** |
| `hypridle` | Idle daemon — triggers lock, DPMS off, suspend after timeouts | `exec.conf`, `hypridle.conf` | Yes | **Required** |
| `hyprlock` | Lock screen — displays clock, date, username, password field | `hypridle.conf`, `keybinds.conf` (`SUPER+Escape`) | Yes | **Required** |
| `hyprpaper` | Static wallpaper daemon (currently **disabled** in favor of wpaperd) | `hyprpaper.conf`, `exec.conf` (commented out) | Yes | Optional |
| `hyprsunset` | Night/warm color filter — reduces blue light | `exec.conf`, `hyprsunset.conf`, `hyprsunset-toggle.sh`, `hyprsunset-status.sh` | Yes | Recommended |

---

## Bar & UI

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `waybar` | Status bar — displays workspaces, clock, system info, custom modules | `exec.conf`, `config/waybar/` (all files) | Yes | **Required** |
| `wofi` | Application launcher (drun mode) and clipboard picker (dmenu mode) | `hyprland.conf` (`$menu`), `keybinds.conf` (clipboard `SUPER+V`) | Yes | **Required** |
| `mako` | Notification daemon — shows desktop notifications | `exec.conf` (implicitly), `mako-dnd-toggle.sh`, `mako-dnd-status.sh` | Yes | **Required** |

---

## Terminal

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `kitty` | GPU-accelerated terminal emulator | `hyprland.conf` (`$terminal`), `config/kitty/kitty.conf` | Yes | **Required** |
| `kitty-shell-integration` | Shell integration for kitty (prompt tracking, etc.) | `kitty.conf` (implicit) | Yes | Recommended |
| `kitty-terminfo` | Terminfo entries for kitty terminal | System-wide terminal compatibility | Yes | Recommended |

---

## Clipboard

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `cliphist` | Clipboard history manager — stores and retrieves clipboard entries | `exec.conf` (wl-paste pipes to cliphist), `keybinds.conf` (`SUPER+V`, `SUPER+Shift+V`) | Yes | **Required** |
| `wl-clipboard` | Provides `wl-copy` and `wl-paste` — Wayland clipboard tools | `exec.conf` (clipboard watchers), `keybinds.conf` (screenshot copy, clipboard) | Yes | **Required** |

---

## Screenshots

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `grim` | Screenshot tool for Wayland — captures full screen or region | `keybinds.conf` (all screenshot binds: `Print`, `SUPER+Print`, `SUPER+Shift+Print`) | Yes | **Required** |
| `slurp` | Region selector — lets you draw a rectangle to select an area | `keybinds.conf` (region screenshot binds: `SUPER+Print`, `SUPER+Shift+Print`) | Yes | **Required** |

---

## Wallpaper

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `wpaperd` | Wallpaper daemon — rotates static wallpapers from a directory | `exec.conf`, `config/wpaperd/config.toml` | Yes | **Required** |
| `mpv` | Media player — used as dependency for mpvpaper | `pkglist.txt` | Yes | Optional |
| `mpvpaper` | Live wallpaper — plays a video as the desktop background | `scripts/livewall.sh`, `scripts/toggle-livewall.sh` | Yes (AUR) | Optional |

---

## System Utilities

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `jq` | JSON processor — used by scripts for parsing JSON data | Various scripts | Yes | Recommended |
| `playerctl` | Media player controller — play/pause/next/prev | `keybinds.conf` (`XF86AudioNext`, `XF86AudioPause`, etc.) | Yes | Recommended |
| `brightnessctl` | Screen & keyboard backlight control | `keybinds.conf` (`XF86MonBrightnessUp/Down`), `hypridle.conf` (kbd backlight off) | Yes | **Required** |
| `pamixer` | PulseAudio mixer CLI (alternative to wpctl) | Available for scripts | Yes | Optional |

---

## Desktop Integration

| Package | Purpose | Used by | Automated Install | Required |
|---|---|---|---|---|
| `xdg-desktop-portal-hyprland` | XDG portal — enables screen sharing, file dialogs, etc. | System integration (screen sharing in browsers, etc.) | Yes | **Required** |

---

## Package Details and Configuration

These packages are actively used by configs and scripts and are managed automatically by the setup scripts.

### Input Simulation

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `ydotool` | Simulates mouse movement, clicks, and scroll from keyboard | `keybinds.conf` (mouse submap: `SUPER+M`) | AUR: `aur-pkglist.txt` |

`ydotool` requires its daemon to be running:

```bash
sudo systemctl enable --now ydotoold
```

### Power Menu

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `wlogout` | Graphical power/logout menu | `modules/custom.jsonc` (power-btn `on-click`) | AUR: `aur-pkglist.txt` |

### System Monitoring

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `upower` | Battery information (wattage, charge state) | `scripts/power.sh` (battery wattage display) | Official: `pkglist.txt` |

### Live Wallpaper

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `mpvpaper` | Plays video files as live wallpaper via mpv | `scripts/livewall.sh` | AUR: `aur-pkglist.txt` |

### Network & Bluetooth Tray

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `network-manager-applet` | Provides `nm-applet` — network tray icon and nmtui | `exec.conf`, `modules/system.jsonc` (network `on-click: kitty -e nmtui`) | Official: `pkglist.txt` |
| `blueman` | Provides `blueman-applet` — bluetooth tray icon and manager | `exec.conf`, `modules/system.jsonc` (bluetooth `on-click: blueman-manager`) | Official: `pkglist.txt` |

### Authentication

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `polkit-kde-agent` | Privilege elevation dialogs (e.g., for pacman in GUI apps) | `exec.conf` | Official: `pkglist.txt` |

### File Manager

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `thunar` | Graphical file manager | `hyprland.conf` (`$fileManager`), `keybinds.conf` (`SUPER+E`) | Official: `pkglist.txt` |

### Audio (PipeWire)

| Package | Purpose | Used by | Source |
|---|---|---|---|
| `pipewire` | Audio/video server | System audio backend | Official: `pkglist.txt` |
| `pipewire-pulse` | PulseAudio compatibility (provides `pactl`) | `scripts/mic.sh` (microphone mute detection) | Official: `pkglist.txt` |
| `wireplumber` | PipeWire session manager (provides `wpctl`) | `keybinds.conf` (volume controls: `wpctl set-volume`, `wpctl set-mute`), `modules/system.jsonc` (pulseaudio module scroll/click) | Official: `pkglist.txt` |

> [!TIP]
> Most Arch Linux + Hyprland installations already have PipeWire, wireplumber, and a polkit agent installed.

---

## Quick Install Commands

If you choose to perform a manual installation without `bootstrap.sh`:

```bash
# From official repos:
sudo pacman -S --needed - < ~/hypr-dots/pkglist.txt

# From AUR:
yay -S --needed $(cat ~/hypr-dots/aur-pkglist.txt)

# Enable ydotool daemon if you use it:
sudo systemctl enable --now ydotoold
```
