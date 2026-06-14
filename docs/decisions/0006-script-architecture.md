# 0006 - Toggle/Status Script Pattern for Waybar Integration

**Date**: 2026-06-14
**Status**: Accepted

## Context

Waybar custom modules need a way to display status and handle user clicks. The standard approach is exec scripts that output JSON and on-click scripts that toggle state.

## Decision

Implement a toggle/status pair pattern:

- **\*-status.sh**: Outputs JSON (`{"text", "tooltip", "class"}`) for waybar to display
- **\*-toggle.sh**: Toggles the feature on/off, then signals waybar to refresh

**Waybar signal mechanism:**
- Toggle scripts end with `pkill -RTMIN+N waybar` to trigger immediate refresh
- Custom modules define `"signal": N` to listen for `RTMIN+N`
- Currently used signals: `RTMIN+2` (hyprsunset), `RTMIN+3` (dnd)

**Script design:**
- Use `#!/bin/sh` for POSIX-compatible scripts
- Use `pgrep`/`pkill` for process detection
- Output valid JSON with `text`, `tooltip`, and `class` fields
- `class` field enables CSS state styling in waybar

## Alternatives Considered

- **Waybar's built-in modules**: limited to pre-defined functionality, can't handle custom toggles.
- **IPC-based approach**: more complex, requires a daemon or socket.
- **File-based state**: simpler but introduces stale-state risks and race conditions.

## Consequences

- Adding a new togglable feature requires: status script, toggle script, custom module in `custom.jsonc`, CSS in `modules.css` and `states.css`, signal number allocation.
- Signal numbers must not conflict.

## Future Considerations

- Document allocated signal numbers.
- Consider a template script for new toggle/status pairs.
- Next available signal: `RTMIN+4`.
