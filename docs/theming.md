# Desktop themes

Catppuccin Mocha is the default. It uses the original glass effects, terminal palettes, wallpaper rotation in `~/Pictures/wallpapers/` and lock image at `~/Pictures/wallpapers/bg1.jpg`. Fjord pairs a cool dark palette with a mountain landscape. Dune pairs warm light surfaces and dark text with desert artwork.

## Switch themes

From the checkout, run the linker once on installation or upgrade. It recognizes direct links into this checkout and keeps unrelated application configurations.

```sh
./link-configs.sh
./scripts/theme.py list
./scripts/theme.py use dune
./scripts/theme.py current
./scripts/theme.py use catppuccin-mocha
```

The same tool is available at `"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/theme.py"` after installation. Run `use` inside the desktop session for live updates. Use `use fjord --no-reload` to save a selection offline. The selected theme survives login. Reapplying a theme picks up manifest edits and retries live updates.

| Component | What happens on selection |
|---|---|
| Hyprland | Reloads the Lua configuration through hyprctl. The session startup hook runs only at login. |
| Waybar | Reloads its CSS and calendar markup with SIGUSR2. The selected edge and module layout are preserved. |
| Kitty | Reloads its config with SIGUSR1. Windows launched with dynamic background opacity enabled can also change opacity live. |
| Mako | Reloads colors, fonts and borders through makoctl when running. |
| Wpaperd | Restarts the session’s running default daemon to load its new rotation directory. A custom invocation or separately managed service follows its owner's restart procedure. |
| Foot, Wofi, Hyprlock | New terminal windows, launcher invocations and lock screens read the selection on startup. Existing terminal sessions and locks continue running. |

The project themes its own desktop components. The live-video toggle still uses the user's video and monitor settings. A switch during playback defers the static wallpaper refresh until you toggle the video off. Thunar follows the user's GTK and icon themes. Night-light temperature and monitor settings remain in their respective configurations.

## Create a theme

Copy the closest example into a new directory. The directory name is the CLI identifier. Use lowercase ASCII letters, digits, hyphens and underscores, beginning with a letter or digit.

```sh
cp -r themes/fjord themes/aurora
# Edit themes/aurora/theme.toml and replace wallpaper.png with your artwork.
./scripts/theme.py validate aurora
./scripts/theme.py use aurora
```

Each manifest contains a complete `[palette]`. Use the role names in the examples and six hexadecimal digits per color, without a leading hash. All applications consume this palette. Terminal ANSI mapping, calendar markup and GTK selectors are shared across themes.

Set optional keys as shown below. This excerpt supplements a complete palette. Put root-level asset keys before the first table.

```toml
wallpapers = ["ridge.png", "valley.png"]
lockscreen = "night.png"

[style]
ui_font = "JetBrainsMono Nerd Font"
terminal_font = "JetBrains Mono"
terminal_size = 12.5
terminal_opacity = 0.88
rounding = 9
border_width = 2

[overrides.kitty]
terminal_opacity = 1.0

[overrides.waybar]
bar_surface = "17212b"
bar_opacity = 0.85
```

- `wallpapers` is an optional list of PNG files inside the theme directory. The installer validates and copies them into the selected rotation directory. Hyprlock uses the first image unless you provide `lockscreen`. Omitting the list selects the user's Pictures directory. With neither asset key, Hyprlock uses Mocha's original user-supplied lock image.
- `[style]` overrides shared defaults. Set `variant` to `"light"` or `"dark"` to select Foot’s corresponding native color section. Font sizes are in pixels for GTK, points for terminals and Mako. Opacity values range from 0 to 1. Font family names support letters, digits, spaces, dots, underscores and hyphens. See [all style settings](../themes/defaults.toml).
- A component override takes precedence over the palette and style for that application. Supported tables are `hyprland`, `hyprlock`, `waybar`, `wofi`, `mako`, `kitty` and `foot`. Use the tokens referenced in that component's adapter. Waybar and Wofi also expose named GTK palette colors. [Shared adapters](../themes/templates)
- Keep hardware, keybindings, module order and notification timing under `config/`. Theme-specific monitors, shell commands and application config copies are unnecessary.

## Validation and recovery

`./scripts/theme.py validate` checks every discovered manifest, required palette roles, override names, value types and ranges, PNG readability, template substitutions and the generated calendar JSON and wallpaper TOML. `python3 tests/themes.py` exercises the installed entry points and uses native validators where available.

Generated files live under `${XDG_CONFIG_HOME:-$HOME/.config}/hypr-dots-theme/`. The `apps/` directories combine links to shared configuration with theme-specific entry points. The `current` symlink selects a complete build, including its theme ID. A lock serializes switches. A failed validation leaves the previous selection active. A live reload failure reports the component after the selection is saved.

Run `./scripts/theme.py init` to repair missing generated files. It rebuilds the saved theme, falling back to Mocha if that theme is missing or invalid. If the compositor cannot load or rebuild a theme, it continues loading keybindings and the other session modules. Run `./link-configs.sh` to restore missing deployment links. To recover explicitly, run `./scripts/theme.py use catppuccin-mocha`. Edit manifests or the shared native files in the checkout. Generated files are replaced on rebuild.
