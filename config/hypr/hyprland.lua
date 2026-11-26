-- #######################################################################################
-- HYPRLAND ROOT CONFIG (LUA)
-- #######################################################################################
-- This is the main Hyprland configuration entry point.
-- Migrated from legacy hyprland.conf syntax to native Lua API.
--
-- Module architecture:
--   - programs.lua: user application preferences ($terminal, $fileManager, $menu)
--   - exec.lua: autostart services via hyprland.start event hook
--   - keybinds.lua: all keybindings, submaps, mouse binds
--   - windowrules.lua: window rules (float, size, etc.)
--
-- See also: docs/architecture.md for the full config hierarchy.
-- #######################################################################################

-- Ensure relative requires work regardless of invocation working directory
local config_dir = debug.getinfo(1, "S").source:match("@?(.*)/") or "."
package.path = config_dir .. "/?.lua;" .. config_dir .. "/?/init.lua;" .. package.path

-- ################
-- ### MONITORS ###
-- ################
-- See https://wiki.hypr.land/configuring/core/monitors/
-- The built-in panel uses its tested 10-bit SDR profile. Other outputs use
-- their preferred mode, automatic placement and compositor-selected scale.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({
    output   = "desc:Samsung Display Corp. 0x4208",
    mode     = "preferred",
    position = "0x0",
    scale    = 1,
    bitdepth = 10, -- 10-bit SDR: smooth gradients, zero banding, 0ms fullscreen transitions, optimal battery

    -- ### MANUAL HDR MODE ###
    -- To enable full HDR (e.g. for HDR movies/gaming), uncomment the lines below and reload:
--  cm            = "hdredid", -- enables ST.2084 PQ curve using monitor EDID primaries
--  sdrbrightness = 1.2,       -- boost/balance SDR desktop brightness in HDR mode (typical: 1.0 - 1.5)
--  sdrsaturation = 1.0,       -- adjust SDR color saturation in HDR mode
})

-- #############################
-- ### ENVIRONMENT VARIABLES ###
-- #############################
-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- #####################
-- ### LOOK AND FEEL ###
-- #####################
-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 4,
        gaps_out = 8,
        resize_on_border = true,
        allow_tearing = false,
        -- Default layout. Can be toggled at runtime via SUPER+M (master) / SUPER+D (dwindle)
        layout = "master",
    },

    decoration = {
        active_opacity = 1.0,
        dim_inactive = true,
        dim_strength = 0.12,

        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 4,
        },

        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            vibrancy          = 0.1696,
        },
        wobble = {
            enabled = true,
            stiffness = 200,
            damping = 12,
            mass = 1,
            intensity = 0.2,
        },
    },

    animations = {
        enabled = true,
    },

    render = {
        cm_auto_hdr = 0, -- Prevents 2s black screen on fullscreen video; keep 0 for regular use
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers (default = -1)
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },

    input = {
        kb_layout   = "us",
        kb_options  = "caps:escape",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
            scroll_factor  = 0.7,
        },
    },
})

require("theme")

-- https://wiki.hypr.land/configuring/core/animations/
-- Bezier format: name, x1, y1, x2, y2 (CSS cubic-bezier control points)
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",     enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",     enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",    enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fade",       enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- See https://wiki.hypr.land/configuring/core/gestures/
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- #########################
-- ### SOURCE OTHER FILES ##
-- #########################
-- Sourced Lua modules load application definitions, autostart services,
-- keybindings and window rules cleanly into the compositor environment.
require("exec")
require("keybinds")
require("windowrules")

