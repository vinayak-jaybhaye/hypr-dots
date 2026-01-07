#!/usr/bin/env bash
set -e

HYPR_DOTS="$HOME/hypr-dots"
PKGS="$HYPR_DOTS/pkglist.txt"

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

if [ ! -f "$PKGS" ]; then
  echo "pkglist.txt not found"
  exit 1
fi

read -rp "Install packages from pkglist.txt? [y/N] " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  info "Installing packages…"
  sudo pacman -S --needed - < "$PKGS"
else
  info "Skipping package installation"
fi
