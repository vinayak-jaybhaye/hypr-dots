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

-- ########################
-- ### LAUNCHERS ##########
-- ########################
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("hyprlock"))

-- ########################
-- ### WINDOW ACTIONS #####
-- ########################
hl.bind(mainMod .. " + C",         hl.dsp.window.close())
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen(2))                 -- window only
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(1))                 -- monitor
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- ########################
-- ### LAYOUT #############
-- ########################

-- Window behavior
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))

-- Toggle master - dwindle layout
-- NOTE: SUPER+M was previously also bound to the mouse submap below.
-- With mouse submap entry commented out, SUPER+M switches to master layout.
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("hyprctl keyword general:layout master"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("hyprctl keyword general:layout dwindle"))

-- ########################
-- ### FOCUS MOVEMENT #####
-- ########################
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- ########################
-- ### WINDOW MOVEMENT ####
-- ########################
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- ########################
-- ### RESIZE #############
-- ########################
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))

-- ########################
-- ### WINDOW OPACITY #####
-- ########################
-- SUBMAP: opacity — SUPER+O enters, press 0-9 to set opacity, ESC to cancel.
-- Each key sets opacity and immediately resets the submap (returns to normal).
hl.bind(mainMod .. " + O", hl.dsp.submap("opacity"))
hl.define_submap("opacity", function()
    for i = 1, 9 do
        hl.bind(tostring(i), hl.dsp.exec_cmd(string.format("hyprctl dispatch setprop active opacity 0.%d; hyprctl dispatch submap reset", i)))
    end
    hl.bind("0", hl.dsp.exec_cmd("hyprctl dispatch setprop active opacity 1.0; hyprctl dispatch submap reset"))
    -- ESC to cancel without changing
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- ########################
-- ### WORKSPACES #########
-- ########################
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- ########################
-- ### SPECIAL WORKSPACE ##
-- ########################

-- Scratchpad (special workspace)
hl.bind(mainMod .. " + grave",         hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mainMod .. " + SHIFT + grave", hl.dsp.window.move({ workspace = "special:scratch" }))
hl.bind(mainMod .. " + CTRL + grave",  hl.dsp.window.move({ workspace = "previous" }))

-- ########################
-- ### CLIPBOARD ##########
-- ########################
hl.bind(mainMod .. " + V",         hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))

-- ########################
-- ### SCREENSHOTS ########
-- ########################
-- Full screen → save + notify
hl.bind("Print", hl.dsp.exec_cmd([[sh -c 'file=~/Pictures/screenshot-$(date +%F-%T).png && grim "$file" && notify-send "Screenshot saved" "$file"']]))

-- Region → save + copy + notify
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd([[sh -c 'file=~/Pictures/screenshot-$(date +%F-%T).png && grim -g "$(slurp)" "$file" && wl-copy < "$file" && notify-send "Screenshot saved & copied" "$file"']]))

-- Region → clipboard only + notify
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd([[sh -c 'grim -g "$(slurp)" - | wl-copy && notify-send "Screenshot copied to clipboard"']]))

-- ########################
-- ### MOUSE ##############
-- ########################
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ########################
-- ### MEDIA / SYSTEM #####
-- ########################
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- ########################
-- ### CUSTOM #############
-- ########################
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/hypr-dots/scripts/toggle-livewall.sh"))

-- Window Groups - group multiple windows into one container
hl.bind(mainMod .. " + G",         hl.dsp.group.toggle())
hl.bind(mainMod .. " + Tab",       hl.dsp.group.next())
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.move_window())

-- SUBMAP: mouse — keyboard-driven cursor control via ydotool.
-- Requires: ydotool (not in pkglist.txt, install separately).
-- Requires: ydotoold systemd service running (systemctl --user enable --now ydotool).
-- SUPER+M enters mouse mode. All keys below work ONLY inside this submap.
-- Press ESC to exit back to normal keybinds.

-- #### UNCOMMENT THIS IF YDOTOOL IS NEEDED
-- hl.bind(mainMod .. " + M", hl.dsp.submap("mouse"))

hl.define_submap("mouse", function()
    -- Movement
    hl.bind("h", hl.dsp.exec_cmd("ydotool mousemove -- -20 0"))
    hl.bind("l", hl.dsp.exec_cmd("ydotool mousemove -- 20 0"))
    hl.bind("k", hl.dsp.exec_cmd("ydotool mousemove -- 0 -20"))
    hl.bind("j", hl.dsp.exec_cmd("ydotool mousemove -- 0 20"))

    -- Faster movement
    hl.bind("SHIFT + h", hl.dsp.exec_cmd("ydotool mousemove -- -100 0"))
    hl.bind("SHIFT + l", hl.dsp.exec_cmd("ydotool mousemove -- 100 0"))
    hl.bind("SHIFT + k", hl.dsp.exec_cmd("ydotool mousemove -- 0 -100"))
    hl.bind("SHIFT + j", hl.dsp.exec_cmd("ydotool mousemove -- 0 100"))

    -- Clicks (ydotool click codes)
    hl.bind("space",  hl.dsp.exec_cmd("ydotool click 0xC0"))    -- left click
    hl.bind("Return", hl.dsp.exec_cmd("ydotool click 0xC1"))  -- right click

    -- Drag (vim-style)
    hl.bind("v", hl.dsp.exec_cmd("ydotool click 0x40"))  -- press
    hl.bind("y", hl.dsp.exec_cmd("ydotool click 0x80"))  -- release

    -- Vertical scroll
    hl.bind("u", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 2"))
    hl.bind("d", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -2"))

    -- Horizontal scroll
    hl.bind("left",  hl.dsp.exec_cmd("ydotool mousemove -w -- -1 0"))
    hl.bind("right", hl.dsp.exec_cmd("ydotool mousemove -w -- 1 0"))

    -- Fast scroll
    hl.bind("up",   hl.dsp.exec_cmd("ydotool mousemove -w -- 0 8"))
    hl.bind("down", hl.dsp.exec_cmd("ydotool mousemove -w -- 0 -8"))

    -- Exit
    hl.bind("escape", hl.dsp.submap("reset"))
end)
