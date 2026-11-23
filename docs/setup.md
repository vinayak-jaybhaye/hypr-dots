# Setup

Use an up-to-date Arch Linux system with Git, sudo, and a working graphics stack. The configuration uses Hyprland's native Lua API. The versions used for validation are Hyprland 0.57.2 and Waybar 0.16.0.

## Installation

Clone the repository into a permanent location, then run `./bootstrap.sh` as your desktop user. Package installation requests sudo internally. To manage packages and configuration independently, use the same two commands bootstrap runs.

```sh
./install-packages.sh
./link-configs.sh
```

The package installer reads the manifests next to the script. Bootstrap accepts the same package mode. The default `ask` mode prompts before installation, `interactive` uses the package manager's prompts, and `auto` adds `--noconfirm`. It uses the local sync databases with `pacman -S --needed`. If your mirrors or databases are stale, complete your normal Arch system upgrade with `sudo pacman -Syu` first. AUR packages go through yay or paru when available. Without either helper, the installer lists the packages needed for the power menu and live wallpaper.

## Links, conflicts and recovery

The linker installs one directory symlink per application in `config/` under `${XDG_CONFIG_HOME:-$HOME/.config}`. The deployed `hypr/scripts` link exposes the repository's executable helpers to Hyprland and Waybar. Keep the checkout in place while using the desktop. Set `HYPR_DOTS` to select another checkout explicitly.

| Command | Existing targets |
|---|---|
| `./link-configs.sh` | Keeps existing targets and reports conflicts |
| `./link-configs.sh --force` | Moves conflicts to a unique `~/.config_backup_*` directory and prints its location |
| `./link-configs.sh --force --no-backup` | Deletes conflicting targets before linking |

Correct links are skipped on every run. After moving the checkout, rerun the linker with `--force` to replace old links. To restore one application, verify its destination with `readlink`, unlink the project symlink, then move the matching backup into its original location.

## Wallpapers and hardware

| Feature | Default or customization |
|---|---|
| Static wallpapers | Put images in `~/Pictures/wallpapers/`. Wpaperd rotates them every ten minutes on each output. |
| Lock screen | Supply `~/Pictures/wallpapers/bg1.jpg` or edit the background path in `config/hypr/hyprlock.conf`. |
| Live wallpaper | Supply `~/Pictures/live-wallpapers/stone-bridge.mp4`. Set `LIVEWALL_VIDEO` or `LIVEWALL_OUTPUT` in the session environment to override the file or output. Super+W toggles playback. |
| Monitor | The laptop rule sets 10-bit SDR and scale 1 on the Samsung 0x4208 panel. Use the description from `hyprctl monitors` when adding another panel-specific rule. The catch-all rule handles other outputs. |
| Temperature | The sensor paths are in `config/waybar/modules/system.jsonc`. Set the hwmon directory and input file for your CPU if the module is blank. |

Foot and Kitty both start zsh. Network controls expect NetworkManager, and Bluetooth controls expect BlueZ and a Bluetooth adapter. Use the services already configured for your machine.

## Verify the desktop

```sh
Hyprland --verify-config -c "$PWD/config/hypr/hyprland.lua"
```

At login, Super+Return should open Foot, Super+R should open Wofi, and Super+E should open Thunar. Use Super+Alt+W to try the four bar edges. Night mode and DND should update immediately on click. Check `hyprctl configerrors` inside the session if a binding fails.
