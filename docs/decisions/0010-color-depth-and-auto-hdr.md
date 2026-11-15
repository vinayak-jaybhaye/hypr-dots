# 0010 — Display Color Depth (10-bit SDR) and Auto-HDR Mitigation

**Date**: 2026-11-15
**Status**: Accepted

## Context

When entering or exiting fullscreen video (e.g., YouTube in Zen Browser, Firefox, Chrome, or media players), the laptop display (`eDP-1`, Samsung ATNA40CT03-0 OLED, 1920×1200 @ 60 Hz driven by Intel Arc Graphics) experienced a disruptive ~2-second black screen.

Investigation into the kernel DRM subsystem (`i915`) and Hyprland's color management pipeline revealed:
1. Hyprland 0.57+ defaults `render:cm_auto_hdr` to `1`, which dynamically attempts an HDR mode switch whenever an application requests HDR or wide-color fullscreen rendering.
2. In the Intel DRM driver (`i915`), upgrading color depth from 8 bpc (24 bpp) to 10 bpc (30 bpp) alongside `HDR_OUTPUT_METADATA` alters DisplayPort link bandwidth calculations, failing the driver's seamless fastset check (`fastset requirement not met in pipe_bpp`).
3. This forces a full display modeset: tearing down the pipe, power-cycling the panel (PPS), re-training the eDP main link (TPS4), and re-initializing the Samsung OLED TCON lookup tables between standard Gamma 2.2 and SMPTE ST.2084 (PQ).
4. During this link retraining and TCON initialization, the OLED panel turns off pixel emission for ~1.5 to 2.0 seconds, repeating when exiting fullscreen back to SDR.

In addition, users need clarity on the distinction between **bit depth (10-bit color depth)** and **true HDR (high dynamic range luminance & EOTF)**, as well as a seamless way to enable HDR manually when needed without sacrificing daily battery life or desktop ergonomics.

## Decision

1. **Disable Automatic Dynamic HDR Modesetting**:
   - Set `render:cm_auto_hdr = 0` in `config/hypr/hyprland.lua`.
   - Hyprland's internal color management (`cm_enabled = true`) remains enabled for accurate SDR gamut mapping, while completely eliminating the 2-second blackout on fullscreen transitions.

2. **Enable Native 10-bit Color Depth for Regular Use**:
   - Set `bitdepth = 10` on the `eDP-1` monitor configuration in `config/hypr/hyprland.lua`.
   - Because `ARGB2101010` uses 32 bits per pixel in memory (identical to `ARGB8888`), and SDR peak luminance is unchanged, 10-bit SDR produces zero perceptible battery penalty on the Intel Arc Arrow Lake GPU.
   - Eliminates color banding across wallpapers, dark UI elements, and gradients on the native 10-bit Samsung OLED panel.

3. **Provide Preset Configuration for Manual HDR Activation**:
   - Document and expose commented HDR configuration entries (`cm = "hdredid"`, `sdrbrightness = 1.2`, `sdrsaturation = 1.0`) directly in the `hl.monitor()` definition in `config/hypr/hyprland.lua`.
   - Allows users to switch cleanly to full-time HDR for movies or gaming by uncommenting three lines and reloading, without enduring disruptive runtime modesets.

## Alternatives Considered

- **Permanent 10-bit HDR full-time**: Rejected for daily use. While eliminating the modeset delay, driving an OLED panel in continuous HDR mode noticeably increases battery consumption, accelerates OLED wear on static desktop UI, and requires tone-mapping compensation (`sdrbrightness`) for standard desktop applications.
- **Selective per-application window rules (`no_auto_hdr`)**: Useful if HDR is specifically desired for media players like `mpv`, but leaves auto-modeset delays active on unlisted apps. `cm_auto_hdr = 0` with manual monitor override is simpler and more predictable.
- **Default 8-bit SDR (`bitdepth` omitted)**: Functional, but leaves the native 10-bit OLED panel underutilized with visible color banding in subtle dark gradients.

## Consequences

- Fullscreen video transitions are instantaneous (0 ms delay, no blackout).
- Daily desktop workflows enjoy smooth, banding-free 10-bit color precision on the Samsung OLED display.
- Optimal laptop battery life and standard panel self-refresh (PSR) behavior are preserved.
- Full hardware HDR10 remains accessible on demand via a simple 3-line uncomment in `hyprland.lua`.
