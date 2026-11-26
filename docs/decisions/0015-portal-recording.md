# 0015 — Capture workspaces and windows through the desktop portal

## Context

Monitor and region recordings follow the pixels currently displayed on an output. A workspace recording needs a source that keeps its identity when another workspace becomes visible.

## Decision

Use Hyprland’s sharing dialog for workspace and window recordings. GPU Screen Recorder requests a fresh PipeWire stream through the desktop portal for each capture. The Settings application owns the encoder process as described in decision 0014. Monitor and region recordings continue to use wf-recorder. [Hyprland workspace sharing](https://hypr.land/news/update57/) · [GPU Screen Recorder manual](https://man.archlinux.org/man/gpu-screen-recorder.1.en)

## Alternatives Considered

Watching workspace-change events while recording a monitor would risk including frames from another workspace during a switch. Implementing a separate Wayland capture client would duplicate source selection, stream negotiation and encoding already available in the portal and recorder.

## Consequences

Closing Settings preserves the active recording. Reopening it shows the current capture mode and stop control. Hyprland and its portal determine which sources the picker offers. Audio captures the default output and can include applications on other workspaces.
