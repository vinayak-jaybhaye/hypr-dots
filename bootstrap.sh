#!/usr/bin/env bash
# bootstrap.sh — Main entry point for setting up hypr-dots
# Purpose: Installs packages from pkglist.txt, then symlinks configs to ~/.config/.
# Usage: ./bootstrap.sh
# Calls: install-packages.sh → link-configs.sh (in sequence)
# See: docs/setup.md for detailed setup documentation.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

"$DIR/install-packages.sh"
"$DIR/link-configs.sh"
