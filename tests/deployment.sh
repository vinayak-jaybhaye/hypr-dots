#!/usr/bin/env bash
# Exercise the public installer and position switcher in a disposable home.
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
sandbox=$(mktemp -d)
trap 'rm -rf -- "$sandbox"' EXIT
export HOME="$sandbox/home"
export XDG_CONFIG_HOME="$HOME/config with spaces"
export XDG_STATE_HOME="$HOME/state with spaces"
export XDG_DATA_HOME="$HOME/data with spaces"
unset HYPR_DOTS WAYLAND_DISPLAY
checkout="$sandbox/renamed checkout"
mkdir -p "$checkout" "$XDG_CONFIG_HOME/kitty" "$sandbox/bin"
cp -a "$root"/{bootstrap.sh,install-packages.sh,link-configs.sh,pkglist.txt,aur-pkglist.txt,config,scripts,themes} "$checkout/"
echo original > "$XDG_CONFIG_HOME/kitty/keep"
ln -s "$checkout/config/foot" "$XDG_CONFIG_HOME/foot"
ln -s "$sandbox/missing" "$XDG_CONFIG_HOME/mako"
cd -- "$sandbox"

# No test path can install packages, start a real bar, or signal the desktop.
for cmd in sudo yay paru pkill waybar; do
	printf '#!/bin/sh\nprintf "%%s\\n" "$0" "$@" >> "$HOME/calls"\n' > "bin/$cmd"
	chmod +x "bin/$cmd"
done
export PATH="$sandbox/bin:$PATH"
printf 'y\ny\n' | "$checkout/bootstrap.sh"
[[ -f "$XDG_CONFIG_HOME/kitty/keep" && -L "$XDG_CONFIG_HOME/mako" && ! -e "$XDG_CONFIG_HOME/mako" ]]
[[ "$XDG_CONFIG_HOME/foot" -ef "$XDG_CONFIG_HOME/hypr-dots-theme/apps/foot" ]]
grep -Fxq pacman "$HOME/calls"
grep -Fxq "$sandbox/bin/yay" "$HOME/calls"
if grep -Eq '^-S.*y' "$HOME/calls"; then exit 1; fi

"$checkout/link-configs.sh" --force
backups=("$HOME"/.config_backup_*)
[[ ${#backups[@]} == 1 && -f "${backups[0]}/kitty/keep" && -L "${backups[0]}/mako" ]]
"$checkout/link-configs.sh" --force
for app in "$checkout"/config/*; do
	[[ "$XDG_CONFIG_HOME/hypr-dots-theme/apps/${app##*/}" -ef "$XDG_CONFIG_HOME/${app##*/}" ]]
done
after=("$HOME"/.config_backup_*)
[[ ${#after[@]} == 1 ]]
[[ -x "$XDG_CONFIG_HOME/hypr/scripts/screenshot.sh" ]]
launcher="$XDG_DATA_HOME/applications/io.github.hyprdots.Settings.desktop"
[[ "$launcher" -ef "$checkout/scripts/io.github.hyprdots.Settings.desktop" ]]
# Exercise the desktop entry's actual argument expansion from a relocated checkout.
printf '#!/bin/sh\ntouch "$HOME/settings-opened"\n' > "$checkout/scripts/settings.py"
gio launch "$launcher"
for _ in {1..30}; do [[ -f "$HOME/settings-opened" ]] && break; sleep 0.1; done
[[ -f "$HOME/settings-opened" ]]
unlink "$launcher"
echo keep > "$launcher"
"$checkout/link-configs.sh"
[[ $(cat "$launcher") == keep ]]

switcher="$XDG_CONFIG_HOME/hypr/scripts/waybar-position.sh"
profile="$XDG_STATE_HOME/hypr-dots/waybar-position.jsonc"
"$switcher" --start
[[ ! -e "$profile" ]]
for edge in left top right bottom; do
	"$switcher" "$edge"
	python3 - "$profile" "$edge" "$XDG_CONFIG_HOME/waybar" <<'PY'
import json
import sys
from pathlib import Path
profile, edge, bar = sys.argv[1:]
selected = json.loads(Path(profile).read_text())
assert selected["position"] == edge
layout = "horizontal" if edge in ("top", "bottom") else "vertical"
assert selected["name"] == layout
assert selected["include"] == [f"config-{layout}.jsonc"]
assert (Path(bar) / selected["include"][0]).is_file()
PY
done
"$switcher" --start
grep -Fxq -- "$profile" "$HOME/calls"
cp "$profile" before
if "$switcher" invalid; then exit 1; fi
cmp before "$profile"
cmp "$root/config/waybar/config.jsonc" "$checkout/config/waybar/config.jsonc"
WAYLAND_DISPLAY=test-only "$switcher" left
grep -Fxq -- -USR2 "$HOME/calls"
# A failed link after a forced backup must put the previous target back.
mkdir -p "$sandbox/rollback/foot"
echo keep > "$sandbox/rollback/foot/original"
printf '#!/bin/sh\nexit 1\n' > "$sandbox/bin/ln"
chmod +x "$sandbox/bin/ln"
if XDG_CONFIG_HOME="$sandbox/rollback" "$checkout/link-configs.sh" --force; then exit 1; fi
[[ -f "$sandbox/rollback/foot/original" ]]
echo "Deployment and Waybar state checks passed."
