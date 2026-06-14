#!/usr/bin/env bash
# install-packages.sh — Install packages from pkglist.txt via pacman
# Purpose: Reads pkglist.txt and aur-pkglist.txt, installing official and AUR packages.
# Modes:
#	ask (default)	— prompts user before installing
#	auto			— installs without prompting (--noconfirm)
#	interactive	— installs with pacman's default prompts
# Usage: ./install-packages.sh [auto|interactive|ask]
# Note: Installs official packages via pacman and AUR packages via yay/paru if detected.
set -e

HYPR_DOTS="$HOME/hypr-dots"
PKGS="$HYPR_DOTS/pkglist.txt"
AUR_PKGS="$HYPR_DOTS/aur-pkglist.txt"

MODE="${1:-ask}"	# auto / interactive / ask

info() {
	echo -e "\033[1;34m[INFO]\033[0m $1"
}

warn() {
	echo -e "\033[1;33m[WARNING]\033[0m $1"
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

info "Installing official packages..."

if [ "$MODE" = "auto" ]; then
	sudo pacman -S --needed --noconfirm - < "$PKGS"
else
	sudo pacman -S --needed - < "$PKGS"
fi

if [ -f "$AUR_PKGS" ]; then
	# Filter packages, removing comments and blank lines
	readarray -t aur_list < <(grep -v -E '^(#|$)' "$AUR_PKGS")
	
	if [ ${#aur_list[@]} -gt 0 ]; then
		# Detect AUR helper
		AUR_HELPER=""
		if command -v yay &>/dev/null; then
			AUR_HELPER="yay"
		elif command -v paru &>/dev/null; then
			AUR_HELPER="paru"
		fi

		if [ -n "$AUR_HELPER" ]; then
			info "Detected AUR helper: $AUR_HELPER"
			install_aur=true
			if [ "$MODE" = "ask" ]; then
				read -rp "Install AUR packages from aur-pkglist.txt? [y/N] " ans_aur
				[[ ! "$ans_aur" =~ ^[Yy]$ ]] && install_aur=false
			fi

			if [ "$install_aur" = true ]; then
				info "Installing AUR packages..."
				if [ "$MODE" = "auto" ]; then
					"$AUR_HELPER" -S --needed --noconfirm "${aur_list[@]}"
				else
					"$AUR_HELPER" -S --needed "${aur_list[@]}"
				fi
			fi
		else
			warn "No AUR helper (yay/paru) detected. Please install an AUR helper or install these AUR packages manually:"
			printf '  - %s\n' "${aur_list[@]}"
		fi
	fi
fi
