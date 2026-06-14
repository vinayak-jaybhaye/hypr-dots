# 0005 - wpaperd as Primary Wallpaper Daemon Over hyprpaper

**Date**: 2026-06-14
**Status**: Accepted

## Context

Multiple wallpaper solutions exist for Hyprland: hyprpaper (official, static), wpaperd (rotation/slideshow), swww (animated transitions).

## Decision

Use wpaperd as the active wallpaper daemon:

- Rotates wallpapers from `~/Pictures/wallpapers/` every 10 minutes
- Configured for `eDP-1` monitor
- hyprpaper config exists but is commented out in `exec.conf` (kept for reference/fallback)
- Live wallpaper option via mpvpaper (separate toggle with `SUPER+W`)

hyprpaper remains in `pkglist.txt` and has a config file, but is not started.

## Alternatives Considered

- **hyprpaper**: static only, no rotation support — too limited for desired workflow.
- **swww**: more features (animated transitions) but heavier resource usage.

## Consequences

- Two wallpaper configs exist which may confuse future agents. wpaperd is the active one. hyprpaper is dormant.

## Future Considerations

- Consider removing hyprpaper from `pkglist.txt` and `exec.conf` if it's confirmed unnecessary.
- Or document a workflow for switching between wpaperd (slideshow) and hyprpaper (static).
