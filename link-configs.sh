#!/usr/bin/env bash
set -e

HYPR_DOTS="$HOME/hypr-dots"
CONFIG_SRC="$HYPR_DOTS/config"
FORCE=0

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

if [[ "$1" == "--force" ]]; then
  FORCE=1
fi

if [ ! -d "$CONFIG_SRC" ]; then
  echo "config/ directory not found in hypr-dots"
  exit 1
fi

for dir in "$CONFIG_SRC"/*; do
  name="$(basename "$dir")"
  target="$HOME/.config/$name"

  if [ -e "$target" ] && [ ! -L "$target" ]; then
    if [ "$FORCE" -eq 1 ]; then
      warn "Removing existing $target"
      rm -rf "$target"
    else
      warn "$target exists — skipping (use --force to replace)"
      continue
    fi
  fi

  mkdir -p "$HOME/.config"
  ln -sfn "$dir" "$target"
  info "linked $target → $dir"
done

# Scripts permissions
if [ -d "$HYPR_DOTS/scripts" ]; then
  chmod +x "$HYPR_DOTS/scripts"/* 2>/dev/null || true
  info "Marked scripts executable"
fi
