# Dependencies

The two manifests are the authoritative installer inputs. Installation modes and conflict handling are described in the [setup guide](setup.md).

| Feature | Packages or commands |
|---|---|
| Compositor and validation | `hyprland` supplies Hyprland and hyprctl. `lua` supplies luac for syntax checks. |
| Theme selection | `python` (3.11+) supplies TOML parsing and `libpng` supplies png2pnm for artwork validation. |
| Lock, idle and night light | `hyprlock`, `hypridle`, `hyprsunset`, `brightnessctl` and systemd |
| Bar, notifications and launcher | `waybar`, `mako` (including makoctl), `libnotify` (notify-send), `wofi` |
| Terminals and file manager | `foot` for Super+Return, `kitty` for Waybar's network terminal, `zsh`, `thunar`, `ttf-jetbrains-mono-nerd`. Kitty pulls in its terminfo and shell integration. |
| Clipboard and screenshots | `wl-clipboard`, `cliphist`, `grim`, `slurp` |
| Wallpaper rotation | `wpaperd` supplies the daemon and wpaperctl. Images come from the selected theme or the user's Pictures directory. |
| Audio and media keys | `pipewire`, `pipewire-pulse`, `wireplumber` (wpctl), `pavucontrol`, `playerctl`. The standalone mic helper uses pactl from libpulse. |
| Tray and authentication | `network-manager-applet` (nm-applet) uses NetworkManager (nmtui), `blueman` supplies the Bluetooth tools, `polkit-kde-agent` provides the Arch authentication agent. |
| Desktop integration | `xdg-desktop-portal-hyprland` and `upower` for the battery power readout |
| Live wallpaper and power menu | The AUR manifest contains `mpvpaper` and `wlogout`. Each is needed for its respective control. |

The disabled mouse submap can be enabled with `ydotool` from Arch's extra repository and its user service `ydotool.service`. Choose a free entry binding when enabling it. The alternative wallpaper configuration requires `hyprpaper` if selected in place of wpaperd.

The installation scripts use Bash, GNU coreutils, util-linux (flock) and pacman on Arch. Runtime process checks and refresh signals use procps-ng. [Official manifest](../pkglist.txt) · [AUR manifest](../aur-pkglist.txt)
