#!/usr/bin/env bash
# bootstrap.sh — Main entry point for setting up hypr-dots
# Purpose: Installs packages from pkglist.txt, then symlinks configs to ~/.config/.
# Usage: ./bootstrap.sh [ask|interactive|auto]
# Calls: install-packages.sh → link-configs.sh (in sequence)
# See: docs/setup.md for detailed setup documentation.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
	echo "Usage: $0 [ask|interactive|auto]"
	exit 0
fi

"$DIR/install-packages.sh" "$@"
"$DIR/link-configs.sh"
