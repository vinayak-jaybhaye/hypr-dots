-- #######################################################################################
-- KEYBINDINGS
-- #######################################################################################
-- All keyboard shortcuts and submaps are defined here using the native Lua API (hl.bind, hl.dsp).
-- Uses programs defined in require("programs").
--
-- SUBMAP WARNING: This file contains two submaps (opacity, mouse). Submaps capture
-- ALL input until explicitly exited. Always ensure every submap has an escape/exit
-- binding that resets to the default submap (hl.dsp.submap("reset")).
-- #######################################################################################

local programs    = require("programs")
local terminal    = programs.terminal
local fileManager = programs.fileManager
local menu        = programs.menu

local mainMod = "SUPER"
local scripts = '"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/"'

-- ########################
-- ### LAUNCHERS ##########
-- ########################
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager), { description = "Open file manager" })
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu), { description = "Open application launcher" })
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("hyprlock"), { description = "Lock screen" })

-- ########################
-- ### WINDOW ACTIONS #####
-- ########################
hl.bind(mainMod .. " + C",         hl.dsp.window.close(), { description = "Close focused window" })
-- Fullscreen: entire screen
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen({ mode = "fullscreen" }), { description = "Toggle fullscreen" })

-- Maximize: preserve gaps and Waybar space
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }), { description = "Toggle maximized window" })
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit(), { description = "Exit Hyprland" })

-- Floating window management
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(mainMod .. " + ALT + C",   hl.dsp.window.center(), { description = "Center floating window" })
hl.bind(mainMod .. " + ALT + P",   hl.dsp.window.pin(), { description = "Toggle pinning on all workspaces" })
hl.bind(mainMod .. " + ALT + H",   hl.dsp.window.alter_zorder({ mode = "bottom" }), { description = "Lower window to bottom" })
hl.bind(mainMod .. " + ALT + L",   hl.dsp.window.alter_zorder({ mode = "top" }), { description = "Raise window to top" })

-- ########################
-- ### LAYOUT #############
-- ########################

-- Window behavior
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo(), { description = "Toggle window pseudotiling" })
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })

-- Toggle master - dwindle layout
-- NOTE: SUPER+M was previously also bound to the mouse submap below.
-- With mouse submap entry commented out, SUPER+M switches to master layout.
hl.bind(mainMod .. " + M", function() hl.config({ general = { layout = "master" } }) end, { description = "Use master layout" })
hl.bind(mainMod .. " + D", function() hl.config({ general = { layout = "dwindle" } }) end, { description = "Use dwindle layout" })

-- ########################
-- ### FOCUS MOVEMENT #####
-- ########################
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus window to the left" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus window to the right" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus window above" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus window below" })

-- ########################
-- ### WINDOW MOVEMENT ####
-- ########################
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { description = "Move window left" })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { description = "Move window right" })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { description = "Move window up" })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { description = "Move window down" })

-- ########################
-- ### RESIZE #############
-- ########################
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { description = "Decrease window width" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { description = "Increase window width" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { description = "Decrease window height" })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { description = "Increase window height" })

-- ########################
-- ### WINDOW OPACITY #####
-- ########################
-- SUBMAP: opacity — SUPER+O enters, press 0-9 to set opacity, ESC to cancel.
-- Each key sets opacity and immediately resets the submap (returns to normal).
hl.bind(mainMod .. " + O", hl.dsp.submap("opacity"), { description = "Enter window opacity submap" })
hl.define_submap("opacity", function()
    for i = 1, 9 do
        local opacity = i / 10

        hl.bind(tostring(i), function()
            hl.dispatch(hl.dsp.window.set_prop({
                prop = "opacity",
                value = tostring(opacity),
            }))
            hl.dispatch(hl.dsp.submap("reset"))
        end, { description = ("Set window opacity to %d%%"):format(i * 10) })
    end

    hl.bind("0", function()
        hl.dispatch(hl.dsp.window.set_prop({
            prop = "opacity",
            value = "1.0",
        }))
        hl.dispatch(hl.dsp.submap("reset"))
    end, { description = "Set window opacity to 100%" })

    hl.bind("escape", hl.dsp.submap("reset"), { description = "Exit opacity submap" })
end)

-- ########################
-- ### WORKSPACES #########
-- ########################
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }), { description = ("Switch to workspace %d"):format(i) })
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { description = ("Move window to workspace %d"):format(i) })
end

-- ########################
-- ### SPECIAL WORKSPACE ##
-- ########################

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("scratch"), { description = "Toggle scratchpad" })
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }), { description = "Move window to scratchpad" })
hl.bind(mainMod .. " + CTRL + grave",  hl.dsp.window.move({ workspace = "previous" }), { description = "Move window to previous workspace" })

-- ########################
-- ### CLIPBOARD ##########
-- ########################
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"), { description = "Open clipboard history" })
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"), { description = "Clear clipboard history" })

-- ########################
-- ### SCREENSHOTS ########
-- ########################
-- Full screen → save + notify
hl.bind("Print", hl.dsp.exec_cmd(scripts .. "screenshot.sh full"), { description = "Save full-screen screenshot" })

-- Region → save + copy + notify
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd(scripts .. "screenshot.sh region"), { description = "Save and copy region screenshot" })

-- Region → clipboard only + notify
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(scripts .. "screenshot.sh clipboard"), { description = "Copy region screenshot to clipboard" })

-- ########################
-- ### MOUSE ##############
-- ########################
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true, description = "Drag window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Focus next workspace" })
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { description = "Focus previous workspace" })

-- ########################
-- ### MEDIA / SYSTEM #####
-- ########################
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, description = "Raise speaker volume" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, description = "Lower speaker volume" })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true, description = "Toggle speaker mute" })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true, description = "Toggle microphone mute" })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true, description = "Increase brightness" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true, description = "Decrease brightness" })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, description = "Play next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Toggle media playback" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Toggle media playback" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, description = "Play previous track" })

-- ########################
-- ### CUSTOM #############
-- ########################
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(scripts .. "toggle-livewall.sh"), { description = "Toggle live wallpaper" })
hl.bind(mainMod .. " + ALT + W",   hl.dsp.exec_cmd(scripts .. "waybar-position.sh"), { description = "Choose Waybar position" })

-- Window Groups - group multiple windows into one container
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle(), { description = "Toggle window group" })
hl.bind(mainMod .. " + Tab",       hl.dsp.group.next(), { description = "Focus next window in group" })
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.move_window(), { description = "Move window within group" })

-- SUBMAP: mouse — keyboard-driven cursor control via ydotool.
-- Requires: ydotool (not in pkglist.txt, install separately).
-- Requires: ydotoold systemd service running (systemctl --user enable --now ydotool).
-- SUPER+M enters mouse mode. All keys below work ONLY inside this submap.
-- Press ESC to exit back to normal keybinds.

-- #### UNCOMMENT THIS IF YDOTOOL IS NEEDED
-- hl.bind(mainMod .. " + M", hl.dsp.submap("mouse"))

-- hl.define_submap("mouse", function()
--     -- Movement
--     hl.bind("h", hl.dsp.exec_cmd("ydotool mousemove -- -20 0"))
--     hl.bind("l", hl.dsp.exec_cmd("ydotool mousemove -- 20 0"))
--     hl.bind("k", hl.dsp.exec_cmd("ydotool mousemove -- 0 -20"))
--     hl.bind("j", hl.dsp.exec_cmd("ydotool mousemove -- 0 20"))
--
--     -- Faster movement
--     hl.bind("SHIFT + h", hl.dsp.exec_cmd("ydotool mousemove -- -100 0"))
--     hl.bind("SHIFT + l", hl.dsp.exec_cmd("ydotool mousemove -- 100 0"))
--     hl.bind("SHIFT + k", hl.dsp.exec_cmd("ydotool mousemove -- 0 -100"))
--     hl.bind("SHIFT + j", hl.dsp.exec_cmd("ydotool mousemove -- 0 100"))
--
--     -- Clicks (ydotool click codes)
--     hl.bind("space",  hl.dsp.exec_cmd("ydotool click 0xC0"))    -- left click
--     hl.bind("Return", hl.dsp.exec_cmd("ydotool click 0xC1"))  -- right click
--
--     -- Drag (vim-style)
--     hl.bind("v", hl.dsp.exec_cmd("ydotool click 0x40"))  -- press
--     hl.bind("y", hl.dsp.exec_cmd("ydotool click 0x80"))  -- release
--
--     -- Vertical scroll
--     hl.bind("u", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 2"))
--     hl.bind("d", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -2"))
--
--     -- Horizontal scroll
--     hl.bind("left",  hl.dsp.exec_cmd("ydotool mousemove -w -- -1 0"))
--     hl.bind("right", hl.dsp.exec_cmd("ydotool mousemove -w -- 1 0"))
--
--     -- Fast scroll
--     hl.bind("up",   hl.dsp.exec_cmd("ydotool mousemove -w -- 0 8"))
--     hl.bind("down", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -8"))
--
--     -- Exit
--     hl.bind("escape", hl.dsp.submap("reset"))
-- end)
