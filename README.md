# hypr-dots

A Hyprland desktop with Catppuccin Mocha as its default theme for Arch Linux. Foot opens on Super+Return, Wofi launches applications, and Waybar can sit on any of the four screen edges. The master and dwindle layouts, Vim-style window controls, clipboard history, and wallpaper controls are configured in native Lua and shell.

## Install

From an up-to-date Arch system, run these commands as your desktop user.

```sh
git clone https://github.com/vinayak-jaybhaye/hypr-dots.git
cd hypr-dots
./bootstrap.sh
```

You can clone anywhere. Bootstrap offers to install the official packages, offers the AUR packages when yay or paru is available, then links each application's directory under `$XDG_CONFIG_HOME` (normally `~/.config`). Existing configurations are skipped. To adopt the project configuration for conflicting apps, `./link-configs.sh --force` backs them up first. Mocha uses your wallpaper directory. Fjord and Dune include their own artwork. [Setup and recovery](docs/setup.md)

## Themes

Run `./link-configs.sh` once when upgrading an existing installation. Then select a theme from inside the desktop session.

```sh
./scripts/theme.py list
./scripts/theme.py use fjord
./scripts/theme.py use dune
./scripts/theme.py use catppuccin-mocha
```

Your selection survives login. See the [theme guide](docs/theming.md) for live reload behavior, customization, validation and recovery.

## Where to make changes

| Where | What it controls |
|---|---|
| `config/hypr/` | Display profiles, compositor settings, application defaults, shortcuts, startup, lock and idle |
| `config/waybar/` | Horizontal and vertical layouts, shared module definitions, shared widget styles |
| `config/{foot,kitty,mako,wofi,wpaperd}/` | Native configuration for each application |
| `themes/` | Discoverable palettes, artwork, shared style defaults and native adapters |
| `scripts/` | Executable desktop helpers shared by shortcuts and Waybar |
| `bootstrap.sh`, `install-packages.sh`, `link-configs.sh` | Full setup, packages only, and links only |
| `pkglist.txt`, `aur-pkglist.txt` | Arch and AUR package manifests |
| `docs/decisions/` | Design decisions and their history |

The reference laptop keeps its 10-bit SDR panel profile. Other outputs use their preferred mode. Edit the named monitor rule in `config/hypr/hyprland.lua` to tune a specific display. Super+Alt+W saves the bar position for the current user.

## Documentation

- [Setup](docs/setup.md) and [dependencies](docs/dependency-reference.md)
- [Shortcuts and daily workflows](docs/workflows.md) and [customization](docs/customization-guide.md)
- [Architecture](docs/architecture.md) and [repository map](docs/repository-map.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Contributor instructions](AGENTS.md) and [style guide](docs/style-guide.md)

<!-- Screenshots coming soon -->

Run `python3 tests/themes.py` for theme switching and recovery. Run `./tests/deployment.sh` for an isolated installation and bar-position smoke test. It uses Bash and Python 3, with stand-ins for the package managers and desktop processes.
