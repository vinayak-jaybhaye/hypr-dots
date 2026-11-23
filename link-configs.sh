#!/usr/bin/env bash
# link-configs.sh — Symlink config directories to $XDG_CONFIG_HOME/
# Purpose: Creates symlinks from this repo's config/ subdirectories to $XDG_CONFIG_HOME/.
# Flags:
#   --force      — replace existing configs (backs up by default)
#   --no-backup  — skip backup when using --force (destructive!)
# Behavior:
#   - Skips directories that are already correctly symlinked
#   - Backs up existing configs to ~/.config_backup_<timestamp>/
#   - Runtime scripts ship executable in Git
# Environment:
#   HYPR_DOTS — override the repo path (default: directory containing this script)
# CAUTION: Bugs in this script can delete user configs. Test changes carefully.
set -euo pipefail

HYPR_DOTS="$(cd -- "${HYPR_DOTS:-$(dirname -- "${BASH_SOURCE[0]}")}" && pwd -P)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CONFIG_SRC="$HYPR_DOTS/config"
FORCE=0
BACKUP=1
BACKUP_DIR=""

info() {
	printf '[INFO] %s\n' "$1"
}

warn() {
	printf '[WARN] %s\n' "$1" >&2
}

error() {
	printf '[ERROR] %s\n' "$1" >&2
}

# -------------------------------
# Parse args
# -------------------------------
for arg in "$@"; do
	case "$arg" in
		-h|--help) echo "Usage: $0 [--force [--no-backup]]"; exit 0 ;;
		--force) FORCE=1 ;;
		--no-backup) BACKUP=0 ;;
		*) error "Unknown option: $arg" >&2; exit 2 ;;
	esac
done

# -------------------------------
# Checks
# -------------------------------
if [ ! -d "$CONFIG_SRC" ]; then
	error "config/ directory not found in $HYPR_DOTS"
	exit 1
fi

mkdir -p -- "$CONFIG_HOME"
CONFIG_HOME="$(cd -- "$CONFIG_HOME" && pwd -P)"
# Serialize replacements and backups when two installers target the same home.
exec {lock_fd}<"$CONFIG_HOME"
flock "$lock_fd"

# -------------------------------
# Link configs
# -------------------------------
for dir in "$CONFIG_SRC"/*; do
	[ -d "$dir" ] || continue

	name="$(basename "$dir")"
	target="$CONFIG_HOME/$name"

	# Never move or remove the checkout containing our sources.
	if [[ "$dir" == "$target" ]]; then
		continue
	elif [[ "$HYPR_DOTS/" == "$target/"* ]]; then
		error "Destination contains the checkout: $target" >&2
		exit 1
	fi

	# If correct symlink already exists → skip
	if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$dir" ]; then
		info "$name already linked — skipping"
		continue
	fi

	saved=""
	# If something exists at target
	if [[ -e "$target" || -L "$target" ]]; then
		if [ "$FORCE" -eq 1 ]; then
			if [ "$BACKUP" -eq 1 ]; then
				if [[ -z "$BACKUP_DIR" ]]; then
					BACKUP_DIR="$(mktemp -d "$HOME/.config_backup_$(date +%s)_XXXXXX")"
				fi
				warn "Backing up $target → $BACKUP_DIR/"
				saved="$BACKUP_DIR/$name"
				mv -T -- "$target" "$saved"
			else
				warn "Removing $target"
				rm -rf -- "$target"
			fi
		else
			warn "$target exists — skipping (use --force to replace)"
			continue
		fi
	fi

	if ! ln -sT -- "$dir" "$target"; then
		# Roll back this replacement if link creation failed after backup.
		if [[ -n "$saved" && ! -e "$target" && ! -L "$target" ]]; then
			mv -T -- "$saved" "$target"
		fi
		exit 1
	fi
	info "linked $target → $dir"
done

info "Done."
