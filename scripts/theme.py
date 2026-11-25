#!/usr/bin/env python3
"""Select and compile a desktop theme without editing the checkout."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import select
import shutil
import signal
import subprocess
import sys
import tempfile
import tomllib

ROOT = Path(__file__).resolve().parents[1]
THEMES = ROOT / "themes"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
STORE = CONFIG / "hypr-dots-theme"
ACTIVE = STORE / "current"
DEFAULT = "catppuccin-mocha"
# Native entry points. All other files in the deployed views link to their source.
OUTPUTS = {
    "hypr/appearance.lua": "hyprland.lua",
    "hypr/hyprlock.conf": "hyprlock.conf",
    "waybar/theme.css": "waybar.css",
    "waybar/theme-calendar.jsonc": "calendar.jsonc",
    "wofi/style.css": "wofi.css",
    "kitty/kitty.conf": "kitty.conf",
    "foot/foot.ini": "foot.ini",
    "mako/config": "mako.conf",
    "wpaperd/config.toml": "wpaperd.toml",
}
PALETTE = set("base mantle crust text subtext0 subtext1 surface0 surface1 surface2 "
              "overlay0 overlay1 overlay2 blue lavender sapphire sky teal green yellow "
              "peach maroon red mauve pink flamingo rosewater".split())
COLORS = PALETTE | {"bar_surface", "glass_edge", "lock_text", "lock_input"}
RANGES = {"terminal_size": (1, 96), "window_opacity": (0, 1), "terminal_opacity": (0, 1),
          "bar_opacity": (0, 1), "bar_font_size": (1, 96), "launcher_font_size": (1, 96),
          "notification_font_size": (1, 96), "launcher_radius": (0, 100), "rounding": (0, 100), "border_width": (0, 20)}
ID = re.compile(r"[a-z0-9][a-z0-9_-]*")
TOKEN = re.compile(r"\{\{(\w+)\}\}")


def read_toml(path):
    with path.open("rb") as stream:
        return tomllib.load(stream)


def table(value, allowed, label):
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a table")
    unknown = value.keys() - allowed
    if unknown:
        raise ValueError(f"unknown {label} keys: {', '.join(sorted(unknown))}")
    return value


def check_values(values):
    for key, value in values.items():
        if key in COLORS:
            valid = isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F]{6}", value)
        elif key == "variant":
            valid = value in ("dark", "light")
        elif key in RANGES:
            low, high = RANGES[key]
            valid = type(value) in (float, int) and low <= value <= high
            if key in {"rounding", "border_width", "launcher_radius", "bar_font_size", "launcher_font_size", "notification_font_size"}:
                valid = valid and type(value) is int
        else:
            valid = isinstance(value, str) and re.fullmatch(r"[\w][\w .-]{0,79}", value)
        if not valid:
            raise ValueError(f"invalid {key}: {value!r}")


def asset_path(folder, asset):
    if not isinstance(asset, str) or Path(asset).is_absolute():
        raise ValueError("wallpaper must be a theme-relative PNG path")
    path = (folder / asset).resolve()
    if not path.is_relative_to(folder.resolve()) or not path.is_file():
        raise ValueError(f"missing or external wallpaper: {asset}")
    if path.suffix.lower() != ".png":
        raise ValueError(f"expected PNG wallpaper: {asset}")
    result = subprocess.run(["png2pnm", path], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=15)
    if result.returncode:
        raise ValueError(f"unreadable PNG wallpaper: {asset}")
    return path


def render(name):
    if not ID.fullmatch(name):
        raise ValueError(f"invalid theme name: {name!r}")
    folder = THEMES / name
    manifest = table(read_toml(folder / "theme.toml"), {"palette", "style", "overrides", "wallpapers", "lockscreen"}, name)
    palette = table(manifest.get("palette"), PALETTE, "palette")
    missing = PALETTE - palette.keys()
    if missing:
        raise ValueError(f"missing palette colors: {', '.join(sorted(missing))}")
    defaults = read_toml(THEMES / "defaults.toml")
    values = palette | defaults | table(manifest.get("style", {}), defaults.keys(), "style")
    check_values(values)
    components = {"hyprland", "hyprlock", "waybar", "wofi", "kitty", "foot", "mako"}
    overrides = table(manifest.get("overrides", {}), components, "overrides")
    assets = manifest.get("wallpapers", [])
    if not isinstance(assets, list):
        raise ValueError("wallpapers must be an array of theme-relative PNG filenames")
    files = {"theme-id": (name + "\n").encode()}
    for i, asset in enumerate(assets):
        files[f"wallpapers/{i}.png"] = asset_path(folder, asset).read_bytes()
    if "lockscreen" in manifest:
        files["lockscreen.png"] = asset_path(folder, manifest["lockscreen"]).read_bytes()
    lock_image = "$HOME/Pictures/wallpapers/bg1.jpg"
    if "lockscreen.png" in files:
        lock_image = str(ACTIVE / "lockscreen.png")
    elif assets:
        lock_image = str(ACTIVE / "wallpapers/0.png")
    wallpaper_path = str(ACTIVE / "wallpapers") if assets else "~/Pictures/wallpapers"
    for dest, template in OUTPUTS.items():
        app = dest.split("/")[0]
        component = template.split(".")[0] if app == "hypr" else app
        source = ROOT / "config" / dest
        path = source if app == "wpaperd" else THEMES / "templates" / template
        adapter = path.read_text()
        if ("{{source}}" in adapter or "{{wofi_uri}}" in adapter) and not source.is_file():
            raise FileNotFoundError(f"missing included config: {source}")
        # Waybar has two adapters sharing a single override table.
        accepted = set(TOKEN.findall(adapter)) & values.keys()
        if app in {"waybar", "wofi"}:
            accepted |= PALETTE | {"glass_edge", "bar_surface"}
        if app == "waybar":
            accepted |= {"ui_font", "bar_font_size", "bar_opacity"}
        local = table(overrides.get(component, {}), accepted, f"overrides.{component}")
        check_values(local)
        options = values | local
        options.update({
            "source": str(source),
            "wofi_uri": (ROOT / "config/wofi/style.css").as_uri(),
            "lock_image": lock_image,
            "wallpaper_path": json.dumps(wallpaper_path, ensure_ascii=False)[1:-1],
            "gtk_palette": "\n".join(f"@define-color {k} #{options[k]};" for k in sorted(PALETTE | {"bar_surface", "glass_edge"}))
                           + "\n@define-color shadow #000000;",
        })
        contents = TOKEN.sub(lambda m: str(options[m[1]]), adapter)
        if template.endswith(".jsonc"):
            json.loads(contents)
        if app == "wpaperd":
            tomllib.loads(contents)
        files[template] = contents.encode()
    return files


def selected():
    try:
        name = (ACTIVE / "theme-id").read_text().strip()
    except (FileNotFoundError, UnicodeError):
        return DEFAULT
    return name


def symlink(target, path):
    """Replace a managed symlink atomically, including a dangling one."""
    if path.is_symlink() and path.readlink() == target:
        return
    if path.exists() and not path.is_symlink():
        raise ValueError(f"expected a managed symlink at {path}")
    with tempfile.TemporaryDirectory(dir=path.parent) as tmp:
        link = Path(tmp) / "link"
        link.symlink_to(target)
        link.replace(path)


def install_views():
    # A stable working directory matters when Waybar reloads relative includes.
    for app in (ROOT / "config").iterdir():
        view = STORE / "apps" / app.name
        view.mkdir(parents=True, exist_ok=True)
        entries = {p.name: p for p in app.iterdir()}
        for dest, template in OUTPUTS.items():
            if Path(dest).parent.name == app.name:
                entries[Path(dest).name] = ACTIVE / template
        for filename, target in entries.items():
            symlink(target, view / filename)


def publish(files):
    builds = STORE / "builds"
    builds.mkdir(exist_ok=True)
    previous = ACTIVE.resolve()
    existing = {str(p.relative_to(previous)) for p in previous.rglob("*") if p.is_file()} if previous.is_dir() else set()
    if existing == files.keys() and all((previous / k).read_bytes() == v for k, v in files.items()):
        return
    build = Path(tempfile.mkdtemp(prefix="theme-", dir=builds))
    try:
        for filename, data in files.items():
            output = build / filename
            output.parent.mkdir(exist_ok=True)
            output.write_bytes(data)
        symlink(build.relative_to(STORE), ACTIVE)
    except BaseException:
        shutil.rmtree(build)
        raise
    # Keep one previous generation for processes finishing an in-flight reload.
    for old in builds.glob("theme-*"):
        if old not in (build, previous) and not old.is_symlink() and (old / "theme-id").is_file():
            shutil.rmtree(old)


def refresh(*, pending_wallpaper_only=False):
    display = os.environ.get("WAYLAND_DISPLAY")
    if not display:
        return
    # A new background layer could cover a playing mpvpaper video.
    pending = STORE / ("pending-wallpaper-" + Path(display).name)
    if pending_wallpaper_only and not pending.exists():
        return
    uid = str(os.getuid())
    session = ["-u", uid, "--env", f"WAYLAND_DISPLAY={display}", "-x"]
    failures = []

    def run(command, absent_ok=False):
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=8)
        except (OSError, subprocess.TimeoutExpired) as error:
            failures.append(str(error))
            return False
        if result.returncode and not (absent_ok and result.returncode == 1):
            failures.append(f"{command[0]}: {result.stderr.strip() or result.stdout.strip() or result.returncode}")
        return result.returncode == 0

    def managed(app):
        return (CONFIG / app).is_symlink() and (CONFIG / app).resolve() == (STORE / "apps" / app).resolve()

    if not pending_wallpaper_only:
        if managed("hypr") and os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            run(["hyprctl", "reload", "config-only"])
        if managed("waybar"):
            # Bars launched by the previous linker still resolve "." inside the checkout.
            for pid in session_pids(session, "waybar"):
                proc = Path("/proc") / str(pid)
                try:
                    if (proc / "cwd").resolve() == ROOT / "config/waybar":
                        replace_process(pid, [CONFIG / "hypr/scripts/waybar-position.sh", "--start"])
                    else:
                        os.kill(pid, signal.SIGUSR2)
                except ProcessLookupError:
                    pass
                except (OSError, RuntimeError) as error:
                    failures.append(f"waybar: {error}")
        if managed("kitty"):
            run(["pkill", "-USR1", *session, "kitty"], absent_ok=True)
        if managed("mako") and run(["pgrep", *session, "mako"], absent_ok=True):
            run(["makoctl", "reload"])
    if managed("wpaperd"):
        pids = session_pids(session, "wpaperd")
        video_playing = not pending_wallpaper_only and run(["pgrep", *session, "mpvpaper"], absent_ok=True)
        if pids and video_playing:
            pending.touch()
            pids = []
        else:
            pending.unlink(missing_ok=True)
        for pid in pids:
            proc = Path("/proc") / str(pid)
            try:
                # The original session hook launched plain wpaperd without arguments.
                # Leave supervised services and explicitly configured daemons to their owner.
                argv = (proc / "cmdline").read_bytes().rstrip(b"\0").split(b"\0")
                if len(argv) == 1 and "/wpaperd.service" not in (proc / "cgroup").read_text():
                    replace_process(pid, ["wpaperd"])
            except (ProcessLookupError, FileNotFoundError):
                pass
            except (OSError, RuntimeError) as error:
                failures.append(f"wpaperd: {error}")
    if failures:
        raise RuntimeError("theme saved; live refresh incomplete:\n  " + "\n  ".join(failures))


def session_pids(session, app):
    result = subprocess.run(["pgrep", *session, app], capture_output=True, text=True, timeout=5)
    if result.returncode == 1:
        return []
    result.check_returncode()
    return [int(pid) for pid in result.stdout.split()]


def replace_process(pid, command):
    if not shutil.which(command[0]):
        raise RuntimeError(f"missing executable: {command[0]}")
    fd = os.pidfd_open(pid)
    try:
        poll = select.poll()
        poll.register(fd, select.POLLIN)
        signal.pidfd_send_signal(fd, signal.SIGTERM)
        if not poll.poll(4000):
            raise RuntimeError("process did not stop in time")
    finally:
        os.close(fd)
    process = subprocess.Popen(command, start_new_session=True, stdin=subprocess.DEVNULL,
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        code = process.wait(timeout=0.25)
    except subprocess.TimeoutExpired:
        return
    raise RuntimeError(f"{command[0]} exited at startup ({code})")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for cmd in ("list", "current", "init"):
        commands.add_parser(cmd)
    commands.add_parser("resume-wallpaper", help="apply a wallpaper change deferred during video playback")
    commands.add_parser("validate").add_argument("name", nargs="?")
    use = commands.add_parser("use")
    use.add_argument("name")
    use.add_argument("--no-reload", action="store_true")
    args = parser.parse_args()
    names = sorted(p.parent.name for p in THEMES.glob("*/theme.toml"))
    if args.command == "list":
        print("\n".join(names))
    elif args.command == "current":
        print(selected())
    elif args.command == "validate":
        if args.name is None and DEFAULT not in names:
            raise ValueError(f"default theme {DEFAULT} is missing")
        for name in [args.name] if args.name else names:
            render(name)
            print(f"{name}: valid")
    else:
        if STORE.resolve().is_relative_to(ROOT):
            raise ValueError("theme runtime directory must be outside the checkout")
        STORE.mkdir(parents=True, exist_ok=True)
        with (STORE / ".lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if args.command == "resume-wallpaper":
                refresh(pending_wallpaper_only=True)
                return
            name = args.name if args.command == "use" else selected()
            try:
                files = render(name)
            except (OSError, ValueError, subprocess.TimeoutExpired) as error:
                if args.command == "use" or name == DEFAULT:
                    raise
                print(f"{name}: {error}; restoring {DEFAULT}", file=sys.stderr)
                name = DEFAULT
                files = render(name)
            if args.command == "init":
                install_views()
            publish(files)
            if args.command == "use":
                if not args.no_reload:
                    refresh()
                print(name)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        sys.exit(f"theme: {error}")
