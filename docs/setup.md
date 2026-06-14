# Setup Guide

Complete installation and setup instructions for the hypr-dots Hyprland desktop environment.

## Prerequisites

Before installing, make sure you have:

| Requirement | Details |
|---|---|
| **OS** | Arch Linux (or Arch-based distro with `pacman`) |
| **Hyprland** | A working Hyprland installation (compositor must already be functional) |
| **Font** | JetBrainsMono Nerd Font — used by kitty, waybar, and hyprlock |
| **Git** | To clone this repository |
| **sudo** | Package installation requires root privileges |

### Install the font

```bash
sudo pacman -S ttf-jetbrains-mono-nerd
```

Or download from [Nerd Fonts](https://www.nerdfonts.com/font-downloads) and install to `~/.local/share/fonts/`.

---

## Quick Install

Clone the repo and run the bootstrap script:

```bash
git clone https://github.com/vinayak-jaybhaye/hypr-dots.git ~/hypr-dots
cd ~/hypr-dots
chmod +x bootstrap.sh
./bootstrap.sh
```

That's it. The bootstrap script handles package installation and config symlinks.

---

## What Each Script Does

### `bootstrap.sh`

The top-level entry point. It simply runs the two setup scripts in order:

1. `install-packages.sh` — installs packages from `pkglist.txt`
2. `link-configs.sh` — symlinks config directories into `~/.config/`

The script uses `set -e` so it aborts on the first error.

### `install-packages.sh`

Installs all packages listed in `pkglist.txt` via `pacman`. Supports three modes:

| Mode | Usage | Behavior |
|---|---|---|
| `ask` (default) | `./install-packages.sh` | Prompts "Install packages from pkglist.txt? [y/N]" before proceeding |
| `auto` | `./install-packages.sh auto` | Installs everything with `--noconfirm` (no prompts at all) |
| `interactive` | `./install-packages.sh interactive` | Runs `pacman -S --needed` so pacman prompts per-package |

In all modes, the script first runs `sudo pacman -Sy --noconfirm` to update the package database. The `--needed` flag ensures already-installed packages are skipped.

### `link-configs.sh`

Creates symlinks from `~/hypr-dots/config/<app>/` → `~/.config/<app>/` for each application directory. This means your configs are always managed from the git repo.

**Behavior:**

- If `~/.config/<app>` is already a symlink pointing to the correct location → **skipped**
- If `~/.config/<app>` exists but is something else → **skipped** (prints a warning)
- After linking, marks all files in `scripts/` as executable

**Flags:**

| Flag | Effect |
|---|---|
| `--force` | Replace existing configs instead of skipping |
| `--no-backup` | When used with `--force`, delete existing configs without backing them up |

**Backup behavior:** When `--force` is used without `--no-backup`, existing configs are moved to `~/.config_backup_<timestamp>/` before being replaced.

```bash
# Safe first run (skips existing configs):
./link-configs.sh

# Replace existing configs (backs them up first):
./link-configs.sh --force

# Replace existing configs (no backup — destructive):
./link-configs.sh --force --no-backup
```

**What gets linked:**

| Source | Target |
|---|---|
| `config/hypr/` | `~/.config/hypr/` |
| `config/kitty/` | `~/.config/kitty/` |
| `config/waybar/` | `~/.config/waybar/` |
| `config/mako/` | `~/.config/mako/` |
| `config/wpaperd/` | `~/.config/wpaperd/` |

> [!IMPORTANT]
> The Hyprland config uses `source = ~/hypr-dots/config/hypr/...` for sourced files, so both the symlink at `~/.config/hypr/` and the actual repo at `~/hypr-dots/` must exist. If you cloned to a different path, update the `source` lines in `hyprland.conf` and the script paths in `keybinds.conf` and waybar module configs.

---

## Manual Setup Steps

If you prefer not to use `bootstrap.sh`, run each step manually:

```bash
# 1. Install packages
sudo pacman -S --needed - < ~/hypr-dots/pkglist.txt

# 2. Create config symlinks
ln -s ~/hypr-dots/config/hypr    ~/.config/hypr
ln -s ~/hypr-dots/config/kitty   ~/.config/kitty
ln -s ~/hypr-dots/config/waybar  ~/.config/waybar
ln -s ~/hypr-dots/config/mako    ~/.config/mako
ln -s ~/hypr-dots/config/wpaperd ~/.config/wpaperd

# 3. Make scripts executable
chmod +x ~/hypr-dots/scripts/*
```

---

## Post-Install Steps

These steps are **not automated** and must be done manually:

### 1. Create wallpaper directories

```bash
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/Pictures/live-wallpapers
```

### 2. Set up the lock screen background

Hyprlock expects a specific file for the lock screen background:

```bash
# Copy or symlink any image to this path:
cp /path/to/your/image.jpg ~/Pictures/wallpapers/bg1.jpg
```

### 3. Add static wallpapers

Place `.jpg` or `.png` files in `~/Pictures/wallpapers/`. The `wpaperd` daemon rotates through them every 10 minutes.

### 4. Add a live wallpaper (optional)

If you want the live wallpaper feature (`SUPER+W`):

```bash
# Place a video file at this exact path:
cp /path/to/video.mp4 ~/Pictures/live-wallpapers/stone-bridge.mp4
```

### 5. Official and AUR dependencies

All dependencies are cataloged and installed automatically:
- Official Arch repository packages are listed in `pkglist.txt` and installed via `pacman`.
- AUR packages are listed in `aur-pkglist.txt` and installed via an AUR helper (`yay`/`paru`) if detected.

If you choose to run the installation steps manually, you can install them using:

```bash
# From official repos:
sudo pacman -S --needed - < ~/hypr-dots/pkglist.txt

# From AUR (using yay):
yay -S --needed $(cat ~/hypr-dots/aur-pkglist.txt)

# ydotool needs its daemon running:
sudo systemctl enable --now ydotoold
```

| Package | Why it's needed |
|---|---|
| `ydotool` | Mouse submap (keyboard-driven cursor control) |
| `wlogout` | Power menu button in waybar |
| `mpvpaper` | Live wallpaper playback |
| `upower` | Battery wattage display script |
| `network-manager-applet` | Network tray icon (`nm-applet`) |
| `blueman` | Bluetooth tray icon (`blueman-applet`) |
| `polkit-kde-agent` | Privilege elevation dialogs |
| `thunar` | File manager (`SUPER+E`) |
| `pipewire` / `pipewire-pulse` / `wireplumber` | Audio backend for `wpctl` and `pactl` |

### 6. Set up a shell

The kitty config is set to use `/usr/bin/zsh`. If you don't have zsh installed:

```bash
sudo pacman -S zsh
# Optionally set as default:
chsh -s /usr/bin/zsh
```

Or change the `shell` line in `config/kitty/kitty.conf` to your preferred shell.

---

## Verify Installation

After setup, log into Hyprland and check:

```bash
# 1. All startup apps should be running:
pgrep -a waybar        # status bar
pgrep -a wpaperd       # wallpaper daemon
pgrep -a hypridle      # idle manager
pgrep -a hyprsunset    # night mode
pgrep -a nm-applet     # network tray
pgrep -a blueman-applet # bluetooth tray

# 2. Keybinds should work:
#    SUPER+Return → opens kitty
#    SUPER+R      → opens wofi launcher
#    SUPER+E      → opens thunar

# 3. Waybar should be visible at the top with all modules

# 4. Check for config errors in the Hyprland log:
cat /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | grep -i error
```

> [!TIP]
> If waybar modules show errors or blank content, check that the scripts in `~/hypr-dots/scripts/` are executable (`chmod +x`) and that all required tools (`upower`, `makoctl`, `pactl`, etc.) are installed.
