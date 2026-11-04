-- #######################################################################################
-- WINDOW RULES
-- #######################################################################################
-- Window rules control per-window behavior (float, size, workspace, opacity, etc.).
-- Uses the native Lua hl.window_rule API.
-- #######################################################################################

-- Float specific settings/dialog windows to protect tiling layout
hl.window_rule({
    match = { class = "^(pavucontrol)$" },
    float = true,
    size  = "800 600",
})

hl.window_rule({
    match = { class = "^(blueman-manager)$" },
    float = true,
    size  = "800 500",
})

hl.window_rule({
    match = { class = "^(nm-connection-editor)$" },
    float = true,
    size  = "700 500",
})

hl.window_rule({
    match = { class = "^(file-roller)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" },
    float = true,
})

hl.window_rule({
    match = { class = "^(wlogout)$" },
    float = true,
})

