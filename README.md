# hypr-dots

Hyprland desktop environment dotfiles for Arch Linux — Catppuccin Mocha themed, laptop-optimized, fully scripted setup.

## Features

- **Hyprland** window manager with master layout (toggle to dwindle)
- **Catppuccin Mocha** palette across all components
- **Waybar** status bar with modular config and rich system modules
- **Kitty** terminal, **Wofi** launcher, **Thunar** file manager
- **Wpaperd** rotating wallpapers + **mpvpaper** live wallpaper toggle
- **Hypridle / Hyprlock** idle management and lock screen
- **Hyprsunset** night mode with waybar toggle
- **Mako** notifications with Do Not Disturb toggle
- **Clipboard history** via cliphist + wl-clipboard
- **Screenshots** via grim + slurp (full, region, clipboard)
- **Vim-style HJKL** navigation + opacity and mouse submaps
- One-command bootstrap installer with automatic symlinks

## Quick Install

```bash
git clone https://github.com/vinayak-jaybhaye/hypr-dots.git ~/hypr-dots
cd ~/hypr-dots
./bootstrap.sh
```

This runs `install-packages.sh` (installs packages from `pkglist.txt` via pacman) then `link-configs.sh` (symlinks `config/*` → `~/.config/*` with backup).

> **Note:** Some runtime dependencies are not in `pkglist.txt` — install manually:
> `ydotool`, `wlogout`, `upower`, `mpvpaper`, `nm-applet`, `blueman`

## Repository Structure

```
hypr-dots/
├── bootstrap.sh              # Entry point: install + link
├── install-packages.sh       # Installs packages from pkglist.txt
├── link-configs.sh           # Symlinks config/ → ~/.config/
├── pkglist.txt               # 22 pacman packages
├── config/
│   ├── hypr/                 # Hyprland + ecosystem configs
│   │   ├── hyprland.conf     #   Root config (sources others at bottom)
│   │   ├── exec.conf         #   Autostart services
│   │   ├── keybinds.conf     #   All keybinds + submaps
│   │   ├── windowrules.conf  #   Window rules (currently empty)
│   │   ├── hypridle.conf     #   Idle → lock → dpms → suspend
│   │   ├── hyprlock.conf     #   Lock screen layout
│   │   ├── hyprsunset.conf   #   Night mode color profile
│   │   └── hyprpaper.conf    #   Wallpaper (disabled, using wpaperd)
│   ├── kitty/
│   │   └── kitty.conf        # Terminal: font, colors, opacity
│   ├── mako/
│   │   └── config            # Notifications (empty — uses defaults)
│   ├── waybar/
│   │   ├── config.jsonc      # Root config (includes modules/*.jsonc)
│   │   ├── style.css         # Root stylesheet (imports styles/*.css)
│   │   ├── modules/          # Module definitions + bar layout
│   │   │   ├── left.jsonc    #   Workspaces + window title
│   │   │   ├── center.jsonc  #   Clock + hyprsunset + DND
│   │   │   ├── right.jsonc   #   System modules layout
│   │   │   ├── system.jsonc  #   Built-in module definitions
│   │   │   └── custom.jsonc  #   Custom module definitions
│   │   └── styles/           # Modular stylesheets
│   │       ├── base.css      #   Catppuccin Mocha CSS variables
│   │       ├── modules.css   #   Module colors + hover effects
│   │       ├── states.css    #   State styles + blink animation
│   │       └── workspaces.css#   Workspace button styles
│   └── wpaperd/
│       └── config.toml       # Wallpaper rotation (eDP-1, 10min)
├── scripts/                  # Waybar helpers + utilities
│   ├── hyprsunset-status.sh  #   Night mode status JSON
│   ├── hyprsunset-toggle.sh  #   Night mode toggle
│   ├── mako-dnd-status.sh    #   DND status JSON
│   ├── mako-dnd-toggle.sh    #   DND toggle
│   ├── mic.sh                #   Microphone mute status JSON
│   ├── power.sh              #   Battery wattage text
│   ├── livewall.sh           #   Start mpvpaper live wallpaper
│   └── toggle-livewall.sh    #   Toggle mpvpaper on/off
└── docs/                     # Detailed documentation
    ├── architecture.md       #   System architecture + dependencies
    └── repository-map.md     #   Complete file-by-file reference
```

<!-- Screenshots coming soon -->

## Documentation

See [`docs/`](docs/) for detailed documentation:

- [**Architecture**](docs/architecture.md) — config hierarchy, startup sequence, theme system, component dependencies
- [**Repository Map**](docs/repository-map.md) — every file's purpose and modification guidelines

For AI agents and automated tools, see [**AGENTS.md**](AGENTS.md).

## Contributing

1. Read [AGENTS.md](AGENTS.md) before making changes — it contains architectural rules and modification guidelines
2. Test shell scripts with `bash -n` before committing
3. Verify JSON syntax on `.jsonc` files
4. Preserve existing comments in all config files
5. Update `docs/repository-map.md` when adding or removing files
