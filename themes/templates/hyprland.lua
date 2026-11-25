hl.config({
    general = {
        border_size = {{border_width}},
        -- Border gradient: Catppuccin Mauve → Blue at 45°
        col = {
            active_border   = { colors = { "rgba({{mauve}}ee)", "rgba({{blue}}ee)" }, angle = 45 },
            inactive_border = "rgba({{surface0}}aa)",
        },
    },
    decoration = {
        rounding = {{rounding}},
        inactive_opacity = {{window_opacity}},
        shadow = {
            color        = "rgba({{crust}}66)",
            color_inactive = "rgba({{crust}}22)",
        },
    },
})
