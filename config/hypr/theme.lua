-- Recover missing theme files before applying the visual settings to the compositor.
local home = os.getenv("XDG_CONFIG_HOME")
if not home or home == "" then home = os.getenv("HOME") .. "/.config" end
local file = home .. "/hypr-dots-theme/apps/hypr/appearance.lua"
local appearance = loadfile(file)
if not appearance then
    local dir = debug.getinfo(1, "S").source:match("@?(.*)/") or "."
    local helper = (dir .. "/scripts/theme.py"):gsub("'", "'\\''")
    os.execute("'" .. helper .. "' init")
    appearance = loadfile(file)
end
-- Keep the session and its keybindings usable even if the theme cannot be rebuilt.
if appearance then
    local ok, err = pcall(appearance)
    if not ok then io.stderr:write("hypr-dots theme: " .. tostring(err) .. "\n") end
else
    io.stderr:write("hypr-dots theme: unable to load " .. file .. "\n")
end
