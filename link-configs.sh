#!/usr/bin/env bash
set -euo pipefail

HYPR_DOTS="${HYPR_DOTS:-$HOME/hypr-dots}"
CONFIG_SRC="$HYPR_DOTS/config"
FORCE=0
BACKUP=1
BACKUP_DIR="$HOME/.config_backup_$(date +%s)"

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# -------------------------------
# Parse args
# -------------------------------
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --no-backup) BACKUP=0 ;;
  esac
done

# -------------------------------
# Checks
# -------------------------------
if [ ! -d "$CONFIG_SRC" ]; then
  error "config/ directory not found in $HYPR_DOTS"
  exit 1
fi

mkdir -p "$HOME/.config"

# -------------------------------
# Link configs
# -------------------------------
for dir in "$CONFIG_SRC"/*; do
  [ -d "$dir" ] || continue

  name="$(basename "$dir")"
  target="$HOME/.config/$name"

  # If correct symlink already exists → skip
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$dir" ]; then
    info "$name already linked — skipping"
    continue
  fi

  # If something exists at target
  if [ -e "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      if [ "$BACKUP" -eq 1 ]; then
        mkdir -p "$BACKUP_DIR"
        warn "Backing up $target → $BACKUP_DIR/"
        mv "$target" "$BACKUP_DIR/"
      else
        warn "Removing $target"
        rm -rf "$target"
      fi
    else
      warn "$target exists — skipping (use --force to replace)"
      continue
    fi
  fi

  ln -s "$dir" "$target"
  info "linked $target → $dir"
done

# -------------------------------
# Scripts permissions
# -------------------------------
if [ -d "$HYPR_DOTS/scripts" ]; then
  find "$HYPR_DOTS/scripts" -type f -exec chmod +x {} \;
  info "Marked scripts executable"
fi

info "Done."
