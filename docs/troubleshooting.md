# Troubleshooting

Common issues and their solutions. Start with the [General Diagnostics](#general-diagnostics) section, then find your specific issue below.

---

## General Diagnostics

```bash
# Check the Hyprland log for errors:
cat /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log | grep -iE "error|warn"

# List running processes to verify daemons:
pgrep -a "waybar|wpaperd|hypridle|hyprsunset|nm-applet|blueman"

# Check if scripts are executable:
ls -la ~/hypr-dots/scripts/

# Test a script manually:
bash -x ~/hypr-dots/scripts/hyprsunset-status.sh
```

---

## Waybar

### Waybar not showing

**Symptoms:** No status bar visible after login.

**Solutions:**

1. Check that waybar is started in `exec.conf`:
   ```bash
   grep waybar ~/hypr-dots/config/hypr/exec.conf
   # Should show: exec-once = waybar
   ```

2. Try launching manually to see errors:
   ```bash
   waybar
   ```

3. Validate the config syntax:
   ```bash
   # Check for JSON syntax errors:
   cat ~/.config/waybar/config.jsonc | python -m json.tool
   ```

4. Check that all included module files exist:
   ```bash
   ls ~/.config/waybar/modules/
   # Should list: left.jsonc, center.jsonc, right.jsonc, system.jsonc, custom.jsonc
   ```

5. Make sure the symlink is correct:
   ```bash
   ls -la ~/.config/waybar
   # Should point to ~/hypr-dots/config/waybar
   ```

### Waybar modules not updating

**Symptoms:** Custom modules (hyprsunset, DND, power) show stale data or are blank.

**Solutions:**

1. Check that scripts are executable:
   ```bash
   chmod +x ~/hypr-dots/scripts/*.sh
   ```

2. Run the status script directly to check output:
   ```bash
   ~/hypr-dots/scripts/hyprsunset-status.sh
   ~/hypr-dots/scripts/mako-dnd-status.sh
   ~/hypr-dots/scripts/power.sh
   ```

3. Verify signal numbers match between toggle and custom module:
   - `custom/hyprsunset` uses signal `2` → toggle sends `pkill -RTMIN+2 waybar`
   - `custom/dnd` uses signal `3` → toggle sends `pkill -RTMIN+3 waybar`

4. Check that required tools are installed:
   ```bash
   which makoctl    # needed for DND status/toggle
   which upower     # needed for power.sh
   which pactl      # needed for mic.sh
   ```

5. Force a manual update:
   ```bash
   pkill -RTMIN+2 waybar   # refresh hyprsunset
   pkill -RTMIN+3 waybar   # refresh DND
   ```

### Waybar shows garbled icons

**Symptoms:** Icons display as squares, rectangles, or missing characters.

**Solution:** Install the Nerd Font:
```bash
sudo pacman -S ttf-jetbrains-mono-nerd
```

Then restart waybar:
```bash
pkill waybar && waybar &
```

---

## Keybindings

### Keybinds not working

**Symptoms:** Pressing keybinds does nothing or does unexpected things.

**Solutions:**

1. **Check if stuck in a submap.** Press `ESC` to return to the default keymap. This is the most common cause — if you entered the opacity submap (`SUPER+O`) or mouse submap (`SUPER+M`) and didn't press `ESC`, all normal keybinds are intercepted.

2. Verify the bind syntax in `keybinds.conf`:
   ```bash
   hyprctl binds | head -50
   ```

3. Check the Hyprland log for bind errors:
   ```bash
   grep -i "bind\|keybind" /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log
   ```

4. Make sure `$mainMod` is defined:
   ```bash
   grep mainMod ~/hypr-dots/config/hypr/keybinds.conf
   # Should show: $mainMod = SUPER
   ```

### Mouse submap stuck

**Symptoms:** HJKL moves the cursor instead of focusing windows. Normal keybinds don't work.

**Solution:** Press `ESC` to exit the mouse submap.

**Prevention:** The mouse submap is entered with `SUPER+M`. Be aware that this key also tries to switch to master layout, but the submap takes precedence.

### Opacity submap stuck

**Symptoms:** Pressing number keys changes window opacity. Normal keybinds don't work.

**Solution:** Press `ESC` to exit the opacity submap.

---

## Hyprland

### Hyprland won't start

**Symptoms:** Black screen, crash to TTY, or error on login.

**Solutions:**

1. Check config syntax from a TTY:
   ```bash
   # Switch to TTY with Ctrl+Alt+F2
   Hyprland 2>&1 | head -50
   ```

2. Verify all sourced files exist:
   ```bash
   ls ~/hypr-dots/config/hypr/exec.conf
   ls ~/hypr-dots/config/hypr/keybinds.conf
   ls ~/hypr-dots/config/hypr/windowrules.conf
   ```

3. Check for syntax errors in the config:
   ```bash
   # Common issues:
   # - Missing closing braces in sections
   # - Invalid monitor names
   # - Typos in dispatcher names
   ```

4. Test with a minimal config:
   ```bash
   # Temporarily rename the config and start fresh:
   mv ~/.config/hypr ~/.config/hypr.bak
   mkdir ~/.config/hypr
   echo "monitor=,preferred,auto,1" > ~/.config/hypr/hyprland.conf
   Hyprland
   ```

### Caps Lock doesn't work

**Expected behavior.** The config maps Caps Lock to Escape:

```conf
input {
    kb_options = caps:escape
}
```

To restore Caps Lock, remove or change `kb_options` in `hyprland.conf`.

---

## Wallpaper

### No wallpaper showing

**Symptoms:** Plain black or default Hyprland background.

**Solutions:**

1. Check that the wallpaper directory exists and has images:
   ```bash
   ls ~/Pictures/wallpapers/
   ```

2. Check that wpaperd is running:
   ```bash
   pgrep wpaperd
   ```

3. Start wpaperd manually to see errors:
   ```bash
   wpaperd
   ```

4. Check the wpaperd config:
   ```bash
   cat ~/.config/wpaperd/config.toml
   # Should show [eDP-1] section with path to wallpapers
   ```

5. Make sure the monitor name matches:
   ```bash
   hyprctl monitors | grep Monitor
   # Should show eDP-1 — update config.toml if different
   ```

### Live wallpaper not working

**Symptoms:** `SUPER+W` does nothing or shows an error.

**Solutions:**

1. Install mpvpaper:
   ```bash
   yay -S mpvpaper
   ```

2. Check the video file exists:
   ```bash
   ls ~/Pictures/live-wallpapers/stone-bridge.mp4
   ```

3. Run the script manually:
   ```bash
   bash -x ~/hypr-dots/scripts/livewall.sh
   ```

4. Check the monitor name in `scripts/livewall.sh`:
   ```bash
   grep MONITOR ~/hypr-dots/scripts/livewall.sh
   # Should match your actual monitor: eDP-1
   ```

---

## Lock Screen

### Lock screen broken or blank

**Symptoms:** Hyprlock shows black screen, crashes, or doesn't display labels.

**Solutions:**

1. Check the background image exists:
   ```bash
   ls ~/Pictures/wallpapers/bg1.jpg
   ```
   If missing, copy any image to that path:
   ```bash
   cp /path/to/any/image.jpg ~/Pictures/wallpapers/bg1.jpg
   ```

2. Check hyprlock config syntax:
   ```bash
   hyprlock --help   # ensure it's installed
   cat ~/.config/hypr/hyprlock.conf
   ```

3. Test hyprlock directly:
   ```bash
   hyprlock
   ```

4. Verify the font is installed:
   ```bash
   fc-list | grep -i jetbrains
   ```

---

## Night Mode (Hyprsunset)

### Night mode not toggling

**Symptoms:** Clicking the hyprsunset waybar icon does nothing, or the icon doesn't update.

**Solutions:**

1. Test the toggle script:
   ```bash
   ~/hypr-dots/scripts/hyprsunset-toggle.sh
   ```

2. Check if hyprsunset process toggles:
   ```bash
   pgrep -x hyprsunset   # should appear/disappear on toggle
   ```

3. Check the status script output:
   ```bash
   ~/hypr-dots/scripts/hyprsunset-status.sh
   # Should output JSON with text, tooltip, class
   ```

4. Verify the waybar signal:
   ```bash
   # The custom module uses signal 2:
   pkill -RTMIN+2 waybar   # force refresh
   ```

---

## Clipboard

### Clipboard history not working

**Symptoms:** `SUPER+V` shows empty list, or pasting doesn't work.

**Solutions:**

1. Check that the clipboard watchers are running:
   ```bash
   pgrep -f "wl-paste.*cliphist"
   ```

2. If not running, check `exec.conf`:
   ```bash
   grep wl-paste ~/hypr-dots/config/hypr/exec.conf
   ```

3. Verify cliphist has entries:
   ```bash
   cliphist list
   ```

4. Test the clipboard chain manually:
   ```bash
   echo "test" | wl-copy
   cliphist list | head -5
   ```

---

## Notifications

### No notifications

**Symptoms:** `notify-send` doesn't show anything.

**Solutions:**

1. Check that mako is running:
   ```bash
   pgrep mako
   ```
   If not, start it:
   ```bash
   mako &
   ```

2. Check if DND mode is enabled:
   ```bash
   makoctl mode
   # If it shows "do-not-disturb", disable it:
   makoctl mode -t do-not-disturb
   ```

3. Test with:
   ```bash
   notify-send "Test" "This is a test notification"
   ```

---

## Bluetooth & Network

### Bluetooth/Network icons missing from tray

**Symptoms:** No bluetooth or network icons in the waybar tray area.

**Solutions:**

1. Install the tray applets:
   ```bash
   sudo pacman -S network-manager-applet blueman
   ```

2. Check they're running:
   ```bash
   pgrep nm-applet
   pgrep blueman-applet
   ```

3. Ensure they're in `exec.conf`:
   ```bash
   grep -E "nm-applet|blueman" ~/hypr-dots/config/hypr/exec.conf
   ```

---

## ydotool (Mouse Submap)

### ydotool not working

**Symptoms:** Mouse submap keys (`SUPER+M` then HJKL) don't move the cursor.

**Solutions:**

1. Install ydotool:
   ```bash
   yay -S ydotool
   ```

2. Enable and start the daemon:
   ```bash
   sudo systemctl enable --now ydotoold
   ```

3. Check daemon status:
   ```bash
   systemctl status ydotoold
   ```

4. Test ydotool directly:
   ```bash
   ydotool mousemove -- 100 0   # should move cursor right
   ```

5. Check permissions — ydotoold needs to access `/dev/uinput`:
   ```bash
   ls -la /dev/uinput
   # Your user may need to be in the 'input' group
   sudo usermod -aG input $USER
   # Log out and back in
   ```

---

## Missing Fonts

### Icons appear as squares or question marks

**Symptoms:** Waybar, kitty, or hyprlock show placeholder characters instead of icons.

**Solution:**

```bash
# Install the Nerd Font:
sudo pacman -S ttf-jetbrains-mono-nerd

# Verify installation:
fc-list | grep -i "JetBrainsMono Nerd"

# Rebuild font cache:
fc-cache -fv

# Restart waybar:
pkill waybar && waybar &
```

---

## Quick Reference: Key Escape Hatches

| Stuck in... | Fix |
|---|---|
| Opacity submap | Press `ESC` |
| Mouse submap | Press `ESC` |
| Frozen screen | `Ctrl+Alt+F2` for TTY, then `SUPER+Shift+Q` to exit Hyprland |
| Black screen after idle | Move mouse or press a key (DPMS will turn display back on) |
| Can't type password on lock | Click the password field area, type blind (input is invisible by design) |
