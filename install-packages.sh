#!/usr/bin/env bash
# install-packages.sh — Install official packages via pacman and AUR packages via yay/paru.
# Usage: ./install-packages.sh [ask|auto|interactive]
# ask prompts before each package group. auto passes --noconfirm.
# interactive uses the package managers' own prompts.
set -euo pipefail

repo_dir="${HYPR_DOTS:-$(dirname -- "${BASH_SOURCE[0]}")}"
mode="${1:-ask}"
flags=(--needed)
usage() { echo "Usage: $0 [ask|auto|interactive]"; }
if (( $# > 1 )); then usage >&2; exit 2; fi
case "$mode" in
	ask|interactive) ;;
	auto) flags+=(--noconfirm) ;;
	-h|--help) usage; exit 0 ;;
	*) usage >&2; exit 2 ;;
esac

# Filter packages, removing comments and blank lines.
read_packages() {
	awk '{ sub(/#.*/, ""); if (NF) print $1 }' "$1"
}
confirm() {
	[[ "$mode" != ask ]] && return 0
	local answer
	read -rp "$1 [y/N] " answer && [[ "$answer" =~ ^[Yy]$ ]]
}

[[ -r "$repo_dir/pkglist.txt" ]] || { echo "Missing $repo_dir/pkglist.txt" >&2; exit 1; }
mapfile -t packages < <(read_packages "$repo_dir/pkglist.txt")
confirm "Install packages from pkglist.txt?" || exit 0
if (( ${#packages[@]} )); then
	sudo pacman -S "${flags[@]}" "${packages[@]}"
fi

[[ -f "$repo_dir/aur-pkglist.txt" ]] || exit 0
mapfile -t aur_packages < <(read_packages "$repo_dir/aur-pkglist.txt")
(( ${#aur_packages[@]} )) || exit 0

# Detect an AUR helper. Manual AUR installation is also supported.
for helper in yay paru; do
	if command -v "$helper" >/dev/null; then
		confirm "Install AUR packages with $helper?" || exit 0
		"$helper" -S "${flags[@]}" "${aur_packages[@]}"
		exit 0
	fi
done
echo "No AUR helper found. Install these packages manually for their desktop controls:" >&2
printf '  %s\n' "${aur_packages[@]}" >&2
