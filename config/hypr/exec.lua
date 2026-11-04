-- #######################################################################################
-- AUTOSTART — commands run once at Hyprland session start.
-- #######################################################################################
-- In Hyprland Lua, the 'hyprland.start' event hook replaces legacy 'exec-once' directives.
-- These run once on fresh login and are not re-triggered on config reload.
-- #######################################################################################

hl.on("hyprland.start", function()
    -- System tray applets
    hl.exec_cmd("nm-applet")                              -- NetworkManager tray icon (requires network-manager-applet)
    hl.exec_cmd("blueman-applet")                         -- Bluetooth tray icon (requires blueman)

    -- Status bar
    hl.exec_cmd("waybar")

    -- Night mode — starts enabled by default; toggle with SUPER+hyprsunset keybind
    hl.exec_cmd("hyprsunset")

    -- Authentication agent — required for GUI apps that need root privileges (e.g. package managers)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Clipboard history — watches for text and image copies, stores for later recall (SUPER+V)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Idle manager — handles screen lock, DPMS off, and suspend after inactivity
    hl.exec_cmd("hypridle")

    -- Wallpaper — wpaperd rotates wallpapers from ~/Pictures/wallpapers/ every 10min
    -- hyprpaper is disabled (see docs/decisions/0005-wpaperd-over-hyprpaper.md)
    -- hl.exec_cmd("hyprpaper")
    hl.exec_cmd("wpaperd")
end)

