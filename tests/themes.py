#!/usr/bin/env python3
"""Exercise public theme commands and installed application entry points in a temporary home."""
import json
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ThemeTests(unittest.TestCase):
    def setUp(self):
        sandbox = tempfile.TemporaryDirectory()
        self.addCleanup(sandbox.cleanup)
        self.home = Path(sandbox.name)
        self.repo = self.home / "renamed checkout"
        self.config = self.home / "config with spaces"
        self.current = self.config / "hypr-dots-theme/current"
        for folder in ("config", "scripts", "themes"):
            shutil.copytree(ROOT / folder, self.repo / folder, symlinks=True)
        self.env = os.environ | {
            "HOME": str(self.home), "XDG_CONFIG_HOME": str(self.config),
            "XDG_RUNTIME_DIR": str(self.home), "WAYLAND_DISPLAY": "",
            "HYPRLAND_INSTANCE_SIGNATURE": "", "DBUS_SESSION_BUS_ADDRESS": "disabled:",
        }
        self.cli = self.repo / "scripts/theme.py"
        self.command(ROOT / "link-configs.sh", env=self.env | {"HYPR_DOTS": str(self.repo)})

    def command(self, *args, env=None, ok=True):
        result = subprocess.run(args, env=env or self.env, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode == 0, ok, (args, result.stdout, result.stderr))
        return result.stdout.strip()

    def test_each_theme_and_native_configs(self):
        self.assertEqual(self.command(self.cli, "list").splitlines(), ["catppuccin-mocha", "dune", "fjord"])
        for name in self.command(self.cli, "list").splitlines():
            with self.subTest(name=name):
                self.command(self.cli, "use", name)
                self.assertEqual(self.command(self.cli, "current"), name)
                build = self.current.resolve()
                self.command(self.cli, "init")
                self.assertEqual(self.current.resolve(), build)
                theme = tomllib.loads((self.repo / "themes" / name / "theme.toml").read_text())
                colors = theme["palette"]
                for path, color in (
                    ("waybar/theme.css", "base"), ("wofi/style.css", "base"),
                    ("hypr/appearance.lua", "mauve"), ("mako/config", "red"),
                    ("kitty/kitty.conf", "blue"), ("foot/foot.ini", "blue"),
                ):
                    self.assertIn(colors[color], (self.config / path).read_text())
                calendar = json.loads((self.config / "waybar/theme-calendar.jsonc").read_text())
                self.assertIn(colors["mauve"], calendar["clock"]["calendar"]["format"]["months"])
                wallpaper = tomllib.loads((self.config / "wpaperd/config.toml").read_text())["any"]
                self.assertEqual(wallpaper["duration"], "10m")
                lock = (self.config / "hypr/hyprlock.conf").read_text()
                if "wallpapers" in theme:
                    image = Path(wallpaper["path"]) / "0.png"
                    self.assertEqual(image.read_bytes(), (self.repo / "themes" / name / "wallpaper.png").read_bytes())
                    self.assertIn(str(image), lock)
                else:
                    self.assertEqual(wallpaper["path"], "~/Pictures/wallpapers")
                    self.assertIn("$HOME/Pictures/wallpapers/bg1.jpg", lock)
                for command in (["luac", "-p", self.config / "hypr/appearance.lua"],
                                ["foot", "-C", "-c", self.config / "foot/foot.ini"]):
                    if shutil.which(command[0]):
                        self.command(*command)
                if shutil.which("Hyprland"):
                    self.assertIn("config ok", self.command("Hyprland", "--verify-config", "-c",
                                                           self.config / "hypr/hyprland.lua"))
                if importlib.util.find_spec("gi"):
                    import gi
                    gi.require_version("Gtk", "3.0")
                    from gi.repository import Gtk
                    Gtk.CssProvider().load_from_path(str(self.config / "waybar/style.css"))
                    Gtk.CssProvider().load_from_data((self.config / "wofi/style.css").read_bytes())
                if shutil.which("kitty"):
                    self.command("kitty", "+runpy",
                                 "import os; from kitty.config import load_config; "
                                 "errors=[]; opts=load_config(os.environ['XDG_CONFIG_HOME'] + '/kitty/kitty.conf', "
                                 "accumulate_bad_lines=errors); assert not errors, errors; "
                                 f"assert int(opts.background) == 0x{colors['base']}; assert opts.scrollback_lines == 5000")

    def test_invalid_theme_and_recovery(self):
        self.command(self.cli, "use", "fjord")
        selected = self.current.resolve()
        manifest = self.repo / "themes/fjord/theme.toml"
        original = manifest.read_text()
        for invalid in (original.replace('base = "192932"', 'base = "#000000"'),
                        original.replace('wallpaper.png', '../dune/wallpaper.png'),
                        original + '\n[overrides.foot]\nwindow_opacity = 0.3\n'):
            manifest.write_text(invalid)
            self.command(self.cli, "validate", "fjord", ok=False)
            self.command(self.cli, "use", "fjord", ok=False)
            self.assertEqual(self.current.resolve(), selected)
        manifest.write_text(original)
        (manifest.parent / "wallpaper.png").write_bytes(b"broken")
        self.command(self.cli, "use", "fjord", ok=False)
        self.assertEqual(self.current.resolve(), selected)
        manifest.unlink()
        self.command(self.cli, "init")
        self.assertEqual(self.command(self.cli, "current"), "catppuccin-mocha")
        (self.current / "hyprland.lua").unlink()
        self.command(self.cli, "init")
        self.assertTrue((self.config / "hypr/appearance.lua").is_file())

    def test_discovery_overrides_and_concurrent_switches(self):
        folder = self.repo / "themes/local"
        shutil.copytree(self.repo / "themes/dune", folder)
        path = folder / "theme.toml"
        path.write_text(path.read_text().replace('["wallpaper.png"]', '["wallpaper.png", "wallpaper.png"]\nlockscreen = "wallpaper.png"')
                        + '\n[overrides.kitty]\nbase = "123456"\nterminal_size = 17\n')
        self.assertIn("local", self.command(self.cli, "list").splitlines())
        self.command(self.cli, "use", "local", "--no-reload")
        self.assertIn("background #123456", (self.config / "kitty/kitty.conf").read_text())
        self.assertNotIn("123456", (self.config / "foot/foot.ini").read_text())
        self.assertTrue((self.current / "wallpapers/1.png").is_file())
        self.assertTrue((self.current / "lockscreen.png").is_file())
        processes = [subprocess.Popen([self.cli, "use", name, "--no-reload"], env=self.env,
                                      stdout=subprocess.DEVNULL) for name in ("dune", "fjord", "local", "catppuccin-mocha")]
        self.assertEqual([proc.wait(timeout=15) for proc in processes], [0] * len(processes))
        final = self.current.resolve()
        self.command(self.cli, "init")
        self.assertEqual(self.current.resolve(), final)
        self.assertEqual(len(list(final.parent.iterdir())), 2)

    def test_video_wallpaper_defers_static_refresh(self):
        bins = self.home / "bin"
        bins.mkdir()
        probe = bins / "pgrep"
        probe.write_text('#!/bin/sh\ncase "$*" in *wpaperd) echo 2147483647;; *mpvpaper) exit 0;; *) exit 1;; esac\n')
        probe.chmod(0o755)
        signaler = bins / "pkill"
        signaler.write_text("#!/bin/sh\nexit 0\n")
        signaler.chmod(0o755)
        session = self.env | {"WAYLAND_DISPLAY": "test-only", "PATH": str(bins) + ":" + self.env["PATH"]}
        self.command(self.cli, "use", "fjord", env=session)
        marker = self.current.parent / "pending-wallpaper-test-only"
        self.assertTrue(marker.is_file())
        self.command(self.repo / "scripts/toggle-livewall.sh", env=session)
        self.assertFalse(marker.exists())

    def test_live_refresh_failure_can_be_retried(self):
        bins = self.home / "bin"
        bins.mkdir()
        for name, code in (("hyprctl", 3), ("pkill", 1), ("pgrep", 1)):
            helper = bins / name
            helper.write_text(f'#!/bin/sh\necho "{name} $*" >> "$HOME/calls"\nexit {code}\n')
            helper.chmod(0o755)
        session = self.env | {"WAYLAND_DISPLAY": "test-only", "HYPRLAND_INSTANCE_SIGNATURE": "test",
                              "PATH": str(bins) + ":" + self.env["PATH"]}
        self.command(self.cli, "use", "fjord", env=session, ok=False)
        self.assertEqual(self.command(self.cli, "current"), "fjord")
        calls = (self.home / "calls").read_text()
        self.assertIn("hyprctl reload config-only", calls)
        self.assertIn("WAYLAND_DISPLAY=test-only", calls)
        self.command(self.cli, "use", "fjord", "--no-reload", env=session)
        self.assertEqual((self.home / "calls").read_text(), calls)


if __name__ == "__main__":
    unittest.main()
