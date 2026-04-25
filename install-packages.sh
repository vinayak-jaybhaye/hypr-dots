#!/usr/bin/env bash
set -e

HYPR_DOTS="$HOME/hypr-dots"
PKGS="$HYPR_DOTS/pkglist.txt"

MODE="${1:-ask}"   # auto / interactive / ask

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

if [ ! -f "$PKGS" ]; then
  echo "pkglist.txt not found"
  exit 1
fi

if [ "$MODE" = "ask" ]; then
  read -rp "Install packages from pkglist.txt? [y/N] " ans
  [[ ! "$ans" =~ ^[Yy]$ ]] && exit 0
fi

echo "[INFO] Updating system..."
sudo pacman -Sy --noconfirm

info "Installing packages..."

if [ "$MODE" = "auto" ]; then
  sudo pacman -S --needed --noconfirm - < "$PKGS"
else
  sudo pacman -S --needed - < "$PKGS"
fi
