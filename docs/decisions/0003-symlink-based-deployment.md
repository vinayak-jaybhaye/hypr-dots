# 0003 - Symlink-Based Configuration Deployment

**Date**: 2026-06-14
**Status**: Accepted

## Context

Dotfiles need to be placed in `~/.config/` to be read by applications. Common approaches: copy, symlink, or GNU stow.

## Decision

Use direct symlinks from `~/hypr-dots/config/*` to `~/.config/*`. Implemented in `link-configs.sh` with:

- Automatic backup of existing configs (timestamped directory)
- `--force` flag to replace existing configs
- `--no-backup` flag to skip backup
- Idempotent: skips already-correct symlinks
- Sets executable permissions on `scripts/`

## Alternatives Considered

- **GNU stow**: additional dependency, abstracts symlink management but adds complexity.
- **Copy**: loses git tracking; edits in `~/.config/` don't propagate back to the repo.
- **XDG_CONFIG_HOME override**: affects all applications, not just the managed ones.

## Consequences

- Editing `~/.config/hypr/` directly edits the repo files. Git tracks all changes. No sync step needed.
- Symlinks can break if the repo is moved.

## Future Considerations

- If repo path changes, re-run `link-configs.sh`.
- Consider adding a `verify-links.sh` script.
- The `HYPR_DOTS` env var can override the default `~/hypr-dots` path.
