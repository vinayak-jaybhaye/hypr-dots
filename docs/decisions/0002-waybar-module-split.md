# 0002 - Waybar Module and Style Separation

**Date**: 2026-06-14
**Status**: Accepted

## Context

Waybar supports including JSON config fragments and CSS `@import`. A single config.jsonc and style.css would grow unwieldy.

## Decision

Split into:

**Config files:**
- **config.jsonc**: bar-level settings + includes for modules
- **modules/left.jsonc**: left-side modules (workspaces, window title)
- **modules/center.jsonc**: center modules (clock, hyprsunset, dnd)
- **modules/right.jsonc**: right-side modules (ordered list of module names)
- **modules/system.jsonc**: system module definitions (cpu, memory, battery, etc.)
- **modules/custom.jsonc**: custom module definitions (power, hyprsunset, dnd)

**Style files:**
- **style.css**: only `@import` directives
- **styles/base.css**: global styles + Catppuccin Mocha CSS variables
- **styles/modules.css**: per-module colors and hover effects
- **styles/states.css**: state-dependent styles (battery warning, muted, etc.)
- **styles/workspaces.css**: workspace button styles

## Alternatives Considered

- **Single file**: simpler but becomes hard to navigate as modules are added.
- **Two files** (config + style): a middle ground, but still grows unwieldy over time.

## Consequences

- Adding a new module requires touching up to 4 files (definition, position, CSS, states). But each file is small and focused.

## Future Considerations

- Document the multi-file update process in AGENTS.md.
- Consider a checklist for new module additions.
