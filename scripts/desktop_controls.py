#!/usr/bin/env python3
"""Desktop control operations shared by the settings window and session startup."""
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
import theme

SCRIPTS = Path(__file__).resolve().parent
STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "hypr-dots"
PREFERENCES = theme.CONFIG / "hypr-dots/preferences.json"
EDGES = ("top", "bottom", "left", "right")
SINK = "@DEFAULT_AUDIO_SINK@"
SOURCE = "@DEFAULT_AUDIO_SOURCE@"


def run(*args, timeout=5):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or f"{Path(args[0]).name} exited with status {result.returncode}")
    return result.stdout.strip()


def previous_theme():
    current = theme.ACTIVE.resolve()
    selected = theme.selected()
    for build in (theme.STORE / "builds").glob("theme-*"):
        if build != current and (build / "theme-id").is_file():
            name = (build / "theme-id").read_text().strip()
            if name != selected and name in theme.theme_names():
                return name
    return None


def edge():
    if (theme.CONFIG / "waybar").resolve() != (theme.STORE / "apps/waybar").resolve():
        raise ValueError("The project Waybar configuration is not linked")
    profile = STATE / "waybar-position.jsonc"
    if not profile.exists():
        profile = theme.CONFIG / "waybar/config.jsonc"
    # Skip JSON strings when stripping JSONC comments and trailing commas.
    string = r'"(?:\\.|[^"\\])*"'
    text = re.sub(rf'({string})|//[^\n]*|/\*.*?\*/', lambda m: m[1] or " ", profile.read_text(), flags=re.S)
    text = re.sub(rf'({string})|,(?=\s*[}}\]])', lambda m: m[1] or "", text)
    profile_data = json.loads(text)
    if not isinstance(profile_data, dict):
        raise ValueError(f"Expected one Waybar profile in {profile}")
    value = profile_data.get("position")
    if value not in EDGES:
        raise ValueError(f"Unknown Waybar position in {profile}")
    return value


def preferences():
    try:
        values = json.loads(PREFERENCES.read_text())
    except FileNotFoundError:
        return {}
    if not isinstance(values, dict) or type(values.get("night_light_at_login", True)) is not bool:
        raise ValueError(f"Invalid night light preference in {PREFERENCES}")
    return values


def night_login():
    return preferences().get("night_light_at_login", True)


def save_night_login(enabled):
    if type(enabled) is not bool:
        raise ValueError("Expected a boolean night light preference")
    save_preference("night_light_at_login", enabled)


def recording_directory():
    from gi.repository import GLib

    saved = preferences().get("recording_directory")
    if saved is None:
        videos = GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_VIDEOS)
        return Path(videos) if videos else Path.home() / "Videos"
    if not isinstance(saved, str) or not Path(saved).is_absolute():
        raise ValueError(f"Invalid recording directory in {PREFERENCES}")
    return Path(saved)


def save_preference(key, value):
    directory = PREFERENCES.parent
    directory.mkdir(parents=True, exist_ok=True)
    with (directory / ".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        values = preferences()
        values[key] = value
        stream = tempfile.NamedTemporaryFile(mode="w", dir=directory, delete=False)
        path = Path(stream.name)
        try:
            with stream:
                json.dump(values, stream, indent=2)
                stream.write("\n")
            path.replace(PREFERENCES)
        finally:
            path.unlink(missing_ok=True)


def night_light():
    if not shutil.which("hyprsunset"):
        raise RuntimeError("hyprsunset is unavailable")
    return run(SCRIPTS / "hyprsunset-toggle.sh", "status") == "on"


def brightness():
    # Machine-readable output: name,class,current,percent,max.
    fields = run("brightnessctl", "-c", "backlight", "-m", "info").split(",")
    return int(fields[3].rstrip("%"))


def volume():
    return round(float(run("env", "LC_ALL=C", "wpctl", "get-volume", SINK).split()[1]) * 100)


def microphone_muted():
    return "[MUTED]" in run("env", "LC_ALL=C", "wpctl", "get-volume", SOURCE)


def dnd():
    return "do-not-disturb" in run("makoctl", "mode").splitlines()


def acquire_idle_inhibitor():
    """Keep the returned FD list alive to hold logind's idle inhibitor."""
    from gi.repository import Gio, GLib

    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    _, fds = bus.call_with_unix_fd_list_sync(
        "org.freedesktop.login1", "/org/freedesktop/login1",
        "org.freedesktop.login1.Manager", "Inhibit",
        GLib.Variant("(ssss)", ("idle", "Hypr Dots Settings", "Keep awake", "block")),
        GLib.VariantType.new("(h)"), Gio.DBusCallFlags.NONE, 3000, None, None)
    return fds


def start_session():
    try:
        enabled = night_login()
    except (OSError, ValueError) as error:
        print(error, file=sys.stderr)
        enabled = True
    if enabled:
        run(SCRIPTS / "hyprsunset-toggle.sh", "on")


if __name__ == "__main__":
    if sys.argv[1:] != ["login"]:
        sys.exit("Usage: desktop_controls.py login")
    try:
        start_session()
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        sys.exit(str(error))
