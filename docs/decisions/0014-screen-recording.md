# 0014 — Manage interactive recordings from Settings

## Context

A screen recording may run longer than the window used to start it. Users also need to choose where recordings go and keep independent captures started from a terminal running.

## Decision

The Settings application owns the `wf-recorder` subprocess and holds itself open during selection, capture and finalization. Closing its window releases the window resources. Opening Settings again while recording returns to Display. Stop sends SIGINT to that subprocess and waits asynchronously for the encoder to finish writing the MP4.

The GTK folder picker stores the destination in the existing project preferences file. Each recording reserves its own filename. Full-monitor capture uses the monitor containing Settings, and region capture uses the desktop’s existing `slurp` picker.

## Alternatives Considered

Tracking a PID in a state file would require stale process detection and recovery. A separate service could support unattended recording, but interactive capture already has an owner and a way to reopen its controls.

## Consequences

Settings stays alive without a window while the capture runs. A successful stop displays the saved path. A failed capture reports an error and retains any nonempty partial video for recovery. The selected folder persists across sessions, and audio is opt-in.
