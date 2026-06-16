# Style Guide & Development Standards

This document establishes the coding conventions, formatting standards, directory rules, and agent behaviors required to maintain the long-term quality and consistency of the `hypr-dots` repository.

---

## Agent Behavior Standards

All automated modification agents and human contributors must adhere to these operational principles:

1. **Read-First Protocol**: Always read [AGENTS.md](../AGENTS.md) and [docs/architecture.md](../docs/architecture.md) before planning or executing any changes.
2. **Preserve Context**: Maintain existing comment headers, explanations, and file structures. Do not delete non-obvious helper logic.
3. **Verify Before Check-in**:
   - Always run `bash -n <script>` to check syntax on shell files.
   - Run JSON/JSONC parsing tests on configuration structures.
4. **Synchronize Docs**: If a keybinding, configuration variable, dependency, script option, or file path changes, update the relevant documents in `docs/` in the same step.
5. **Record Decisions**: For non-trivial modifications (changing active daemons, changing variables, altering stylesheet structures), document them in a new sequentially numbered Architecture Decision Record in `docs/decisions/` following the ADR format.

---

## Shell Scripting Style

Scripts are stored under `scripts/`. Keep scripts short and focused on a single task.

### Shebangs & POSIX Compliance
- **POSIX scripts**: Use `#!/bin/sh` for simple helper scripts. Avoid Bashisms (e.g. `[[ ]]` or local arrays) to ensure fast execution.
- **Bash scripts**: Use `#!/usr/bin/env bash` only if Bash-specific features (such as arrays, process substitutions, or extended regex comparisons) are required.

### Formatting & Syntax
- **Indentation**: Use **tabs** for indentation (conforming to the existing repository style).
- **Error Handling**: Setup scripts (`bootstrap.sh`, `link-configs.sh`) must declare safety flags early:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- **Quoting**: Quote all variables containing file paths or user input to prevent word splitting issues. Simple, static strings do not require excessive quoting.
- **Waybar Output**: Status scripts must output valid JSON to stdout on a single line containing `text`, `tooltip`, and `class` fields. Print error responses to stderr, not stdout.

### Script Naming Conventions
Follow a structured naming format depending on script purpose:
- **Toggles**: `<component>-toggle.sh` (e.g. `hyprsunset-toggle.sh`)
- **Status Indicators**: `<component>-status.sh` (e.g. `mako-dnd-status.sh`)
- **Action helpers**: `<action>-<target>.sh` or simply `<target>.sh` (e.g. `toggle-livewall.sh`, `power.sh`)

---

## Hyprland Configuration Style

Hyprland configurations are stored under `config/hypr/`.

### Formatting
- **Indentation**: Use **4 spaces** for nested configuration blocks.
- **Section Dividers**: Separate distinct logical groups of configuration parameters with full-width comment banners:
  ```
  # #######################################################################################
  # SECTION NAME — Brief description of section
  # #######################################################################################
  ```
- **Sourcing**: Keep `source` directives at the very bottom of the main file.
- **Inline Comments**: Use a single space after `#` for explanation comments. Align comments to the right if explaining individual configuration lines.

---

## Waybar Layout & JSON Style

Waybar configurations are stored under `config/waybar/`.

### JSON/JSONC Standards
- **Indentation**: Use **2 spaces** for indentation.
- **Comments**: Waybar uses a JSONC parser; inline comments (`//`) are allowed and should be used to describe the purpose of custom modules.
- **File Structure**: Always keep layout directives (`modules-left`, `modules-center`, `modules-right`) isolated in separate files under `modules/`.

### Module Naming Rules
- Built-in system modules should match the default Waybar module name (e.g. `"cpu"`, `"memory"`, `"pulseaudio"`).
- Custom modules must start with a `custom/` prefix (e.g. `"custom/hyprsunset"`, `"custom/dnd"`).

---

## Stylesheet (CSS) Standards

Styles are stored under `config/waybar/styles/` or the root `config/waybar/style.css`.

### Colors & Palette Integration
- **Zero Hex Code Rule**: Never hardcode hex color strings (`#ffffff`, `#1e1e2e`) directly inside `modules.css`, `states.css`, or `workspaces.css`.
- **Variable Usage**: All colors must reference the variables defined in [base.css](../config/waybar/styles/base.css) (e.g. `@base`, `@text`, `@mauve`, `@red`).
- **Indentation**: Use **2 spaces** for CSS properties.

---

## Directory Organization Conventions

When expanding or organizing configurations, place files into these folders:

| Directory | Target File Types | Guidelines |
| :--- | :--- | :--- |
| `config/<app>/` | Configuration files | Must match the target directory name in `~/.config/`. |
| `scripts/` | Shell scripts | Executable scripts. Ensure you set permissions (`chmod +x`). |
| `docs/` | Markdown files | Technical user guides and dependency lists. |
| `docs/decisions/` | ADR Markdown files | Decision history files named as `NNNN-slug.md`. |
