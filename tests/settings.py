#!/usr/bin/env python3
"""Exercise settings in a disposable XDG home. Pass --gtk to also exercise the window."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
sys.path.insert(0, str(ROOT / "scripts"))
import desktop_controls as controls
import theme

GUI = "--gtk" in sys.argv
if GUI:
    sys.argv.remove("--gtk")


class SettingsTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        config = self.home / "config with spaces"
        store = config / "hypr-dots-theme"
        state = self.home / "state/hypr-dots"
        self.prefs = config / "hypr-dots/preferences.json"
        self.enterContext(patch.dict(os.environ, {
            "HOME": str(self.home), "PATH": str(self.bin) + ":" + os.environ["PATH"],
            "XDG_CONFIG_HOME": str(config), "XDG_STATE_HOME": str(state.parent),
            "XDG_DATA_HOME": str(self.home / "data"), "HYPRLAND_INSTANCE_SIGNATURE": "",
            "HYPR_DOTS": str(ROOT),
        }))
        self.enterContext(patch.multiple(theme, CONFIG=config, STORE=store, ACTIVE=store / "current"))
        self.enterContext(patch.multiple(controls, STATE=state, PREFERENCES=self.prefs))

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body + "\n")
        path.chmod(0o755)

    def install(self):
        subprocess.run([ROOT / "link-configs.sh"], check=True, stdout=subprocess.DEVNULL)

    def test_preferences_and_login(self):
        with patch.object(controls, "run") as run:
            controls.start_session()
            run.assert_called_once_with(controls.SCRIPTS / "hyprsunset-toggle.sh", "on")
            self.assertFalse(self.prefs.exists())
            self.prefs.parent.mkdir(parents=True)
            self.prefs.write_text('{"another_setting": 7}')
            controls.save_night_login(False)
            self.assertEqual(json.loads(self.prefs.read_text()), {"another_setting": 7, "night_light_at_login": False})
            run.reset_mock()
            controls.start_session()
            run.assert_not_called()
            self.prefs.write_text('{"night_light_at_login":"off"}')
            with self.assertRaises(ValueError):
                controls.save_night_login(True)
            self.assertEqual(self.prefs.read_text(), '{"night_light_at_login":"off"}')
            with patch("sys.stderr"):
                controls.start_session()
            run.assert_called_once()

    def test_theme_and_edge_owners(self):
        self.install()
        self.assertEqual(controls.edge(), "bottom")
        profile = theme.CONFIG / "waybar/config.jsonc"
        profile.unlink()
        profile.write_text('{"note":"// keep /* strings */", /* first */ "position": "left", // last\n}')
        self.assertEqual(controls.edge(), "left")
        self.assertIsNone(controls.previous_theme())
        with patch.dict(os.environ, WAYLAND_DISPLAY=""):
            for name, previous in (("fjord", theme.DEFAULT), ("dune", "fjord")):
                controls.run(controls.SCRIPTS / "theme.py", "use", name)
                self.assertEqual(controls.previous_theme(), previous)
            for edge in controls.EDGES:
                controls.run(controls.SCRIPTS / "waybar-position.sh", edge)
                self.assertEqual(controls.edge(), edge)
        self.assertFalse(self.prefs.exists())
        (theme.CONFIG / "waybar").unlink()
        with self.assertRaises(ValueError):
            controls.edge()

    def mock_recorder(self, program="wf-recorder"):
        recorder = self.bin / program
        recorder.write_text(f"#!{sys.executable}\n" + """import json, os, signal, sys, time
from pathlib import Path
portal = Path(sys.argv[0]).name == "gpu-screen-recorder"
output = Path(sys.argv[sys.argv.index("-o" if portal else "-f") + 1])
stopped = False
def stop(*args):
    global stopped
    stopped = True
signal.signal(signal.SIGINT, stop)
Path(os.environ["HOME"], "recorder-args").write_text(json.dumps(sys.argv[1:]))
if portal:
    while not Path(os.environ["HOME"], "portal-approved").exists():
        if stopped:
            sys.exit(1)
        time.sleep(.02)
    output.write_bytes(b"header")
while not stopped:
    time.sleep(.02)
output.write_bytes(b"finalized")
""")
        recorder.chmod(0o755)

    def test_recording_lifecycle(self):
        from gi.repository import GLib
        from unittest.mock import Mock
        from recording import Recorder

        app = Mock()
        app.get_windows.return_value = [object()]
        recorder = Recorder(app)
        self.mock_recorder()
        folder = self.home / "video clips & demos"
        controls.save_preference("recording_directory", str(folder))
        controls.save_night_login(False)
        self.assertEqual(controls.recording_directory(), folder)
        args_file = self.home / "recorder-args"

        def wait(check):
            end = time.monotonic() + 5
            while time.monotonic() < end:
                while GLib.MainContext.default().iteration(False):
                    pass
                if check():
                    return
                time.sleep(.02)
            self.fail(f"Recorder did not reach expected state ({recorder.phase}, {recorder.message})")

        self.command("slurp", "exit 1")
        recorder.start(folder, False)
        wait(lambda: recorder.phase == "idle")
        self.assertFalse(folder.exists())
        self.assertEqual(recorder.message, "")
        self.command("slurp", "echo '20,30 300x200'")
        for monitor, target in (("test-panel", ["-o", "test-panel"]), (None, ["-g", "20,30 300x200"])):
            with self.subTest(target=target):
                recorder.start(folder, True, monitor)
                wait(args_file.exists)
                args = json.loads(args_file.read_text())
                self.assertEqual(args[:2], target)
                self.assertIn("--audio", args)
                output = Path(args[args.index("-f") + 1])
                self.assertEqual(output.parent, folder)
                self.assertEqual(output.suffix, ".mp4")
                recorder.start(folder, True, monitor)
                recorder.stop()
                wait(lambda: recorder.phase == "idle")
                self.assertIn(str(output), recorder.message)
                self.assertEqual(output.read_bytes(), b"finalized")
                args_file.unlink()
        self.command("wf-recorder", "echo 'capture failed' >&2; exit 1")
        recorder.start(folder, False, "test-panel")
        wait(lambda: recorder.phase == "idle")
        self.assertIn("capture failed", recorder.message)
        self.assertEqual(len(list(folder.iterdir())), 2)
        recorder.start(output, False, "test-panel")
        self.assertEqual(recorder.phase, "idle")

        self.mock_recorder("gpu-screen-recorder")
        recorder.start(folder, False, portal=True)
        wait(args_file.exists)
        self.assertEqual(recorder.phase, "sharing")
        self.assertNotIn("-a", json.loads(args_file.read_text()))
        # Shutdown can end the event loop before child-exit callbacks run.
        event, shutdown = app.connect.call_args.args
        self.assertEqual(event, "shutdown")
        shutdown(app)
        self.assertFalse(recorder.output.exists())
        wait(lambda: recorder.phase == "idle")
        self.assertEqual(recorder.portal_watch, 0)
        args_file.unlink()
        recorder.start(folder, True, portal=True)
        wait(args_file.exists)
        args = json.loads(args_file.read_text())
        self.assertEqual(args[args.index("-w") + 1], "portal")
        self.assertEqual(args[args.index("-restore-portal-session") + 1], "no")
        self.assertEqual(args[args.index("-a") + 1], "default_output")
        (self.home / "portal-approved").touch()
        wait(lambda: recorder.phase == "recording")
        recorder.stop()
        wait(lambda: recorder.phase == "idle")
        self.assertEqual(recorder.output.read_bytes(), b"finalized")
        self.command("gpu-screen-recorder", "echo 'picker canceled by the user' >&2; exit 1")
        recorder.start(folder, False, portal=True)
        wait(lambda: recorder.phase == "idle")
        self.assertIn("cancelled", recorder.message)
        self.assertFalse(recorder.output.exists())
        self.assertEqual(app.hold.call_count, app.release.call_count)

    def test_night_light_session_operations(self):
        # Linux keeps the script name in /proc for the lifetime of its interpreter.
        daemon = self.bin / "hyprsunset"
        daemon.write_text(f"#!{sys.executable}\nimport time\ntime.sleep(20)\n")
        daemon.chmod(0o755)
        helper = controls.SCRIPTS / "hyprsunset-toggle.sh"
        with patch.dict(os.environ, WAYLAND_DISPLAY=f"hypr-dots-test-{os.getpid()}", XDG_RUNTIME_DIR=str(self.home)):
            try:
                self.assertFalse(controls.night_light())
                for _ in range(2):
                    controls.run(helper, "on")
                    self.assertTrue(controls.night_light())
                pids = controls.run("pgrep", "-u", str(os.getuid()), "--env",
                                    "WAYLAND_DISPLAY=" + os.environ["WAYLAND_DISPLAY"], "-x", "hyprsunset")
                self.assertEqual(len(pids.splitlines()), 1)
            finally:
                controls.run(helper, "off")
            controls.run(helper, "off")
            self.assertFalse(controls.night_light())

    @unittest.skipUnless(GUI, "use --gtk with a display to exercise the window")
    def test_window_controls(self):
        import cairo
        import settings
        from gi.repository import Adw, GLib, Gtk

        self.install()
        self.command("pgrep", "exit 1")
        self.command("pkill", "exit 1")
        self.command("wpaperctl", 'echo "$*" >> "$HOME/wallpaper-calls"')
        self.command("wpctl", """case "$1 $2" in
            'get-volume @DEFAULT_AUDIO_SINK@') echo 'Volume: 0.55';;
            'get-volume @DEFAULT_AUDIO_SOURCE@') echo 'Volume: 1.00 [MUTED]';;
            *) echo "$*" >> "$HOME/audio-writes";;
        esac""")
        self.command("brightnessctl", """case "$*" in
            *info) echo 'panel,backlight,35,35%,100';;
            *) echo "$*" >> "$HOME/light-writes";;
        esac""")
        self.command("makoctl", """case "$#" in
            1) echo default; [ ! -f "$HOME/dnd" ] || echo do-not-disturb;;
            *) case "$2" in -a) touch "$HOME/dnd";; -r) rm -f "$HOME/dnd";; *) exit 1;; esac;;
        esac""")

        callback_errors = []
        self.enterContext(patch.object(sys, "excepthook", lambda kind, err, tb: callback_errors.append(err)))
        app = Adw.Application(application_id="io.github.hyprdots.Settings.Test")
        app.keep_awake = settings.KeepAwake(app)
        app.register()
        window = settings.Settings(app, settings.Recorder(app))
        self.addCleanup(window.close)
        window.present()

        def until(check):
            deadline = time.monotonic() + 8
            context = GLib.MainContext.default()
            while time.monotonic() < deadline:
                while context.iteration(False):
                    pass
                if not (window.reading or window.pending_writes or window.debounce) and check():
                    return
                time.sleep(0.02)
            self.fail("Window did not reach expected state")

        def row(key):
            return window.readers[key][3]

        def descendants(widget):
            for child in widget:
                yield child
                yield from descendants(child)

        def scale(key):
            return next(w for w in descendants(row(key)) if isinstance(w, Gtk.Scale))

        until(lambda: row("Theme").get_sensitive())
        self.assertEqual(theme.selected(), theme.DEFAULT)
        self.assertFalse(controls.STATE.exists())
        self.assertFalse(window.restore.get_visible())
        buttons = [w for w in descendants(window.wall_row) if isinstance(w, Gtk.Button)]
        for action, label in (("next", "Next wallpaper"), ("previous", "Previous wallpaper")):
            next(b for b in buttons if b.get_tooltip_text() == label).emit("clicked")
            until(lambda: action in (self.home / "wallpaper-calls").read_text().splitlines())
        row("Theme").set_selected(window.theme_names.index("dune"))
        until(lambda: window.previous == theme.DEFAULT)
        row("Bar position").set_selected(controls.EDGES.index("right"))
        until(lambda: controls.edge() == "right")
        self.assertEqual(window.preview_key[2], "right")
        surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, 480, 140)
        window.draw_preview(window.preview, cairo.Context(surface), 480, 140)
        self.assertTrue(any(surface.get_data()))
        window.restore.emit("activated")
        until(lambda: theme.selected() == theme.DEFAULT)
        window.tabs.set_visible_child_name("display")
        until(lambda: row("Start enabled at login").get_active())
        with patch.object(controls, "acquire_idle_inhibitor", return_value=object()) as acquire:
            row("Keep awake").set_active(True)
            until(lambda: app.keep_awake.lock is not None)
            acquire.assert_called_once()
        self.assertEqual(row("Brightness").get_subtitle(), "35%")
        self.assertFalse(self.prefs.exists())
        self.assertFalse((self.home / "light-writes").exists())
        scale("Brightness").set_value(45)
        scale("Brightness").set_value(46)
        until(lambda: (self.home / "light-writes").exists())
        self.assertEqual((self.home / "light-writes").read_text().splitlines(), ["-c backlight set 46%"])
        row("Start enabled at login").set_active(False)
        until(lambda: not controls.night_login())
        window.tabs.set_visible_child_name("sound")
        until(lambda: row("Mute microphone").get_active())
        self.assertEqual(row("Output volume").get_subtitle(), "55%")
        self.assertFalse((self.home / "audio-writes").exists())
        scale("Output volume").set_value(65)
        until(lambda: (self.home / "audio-writes").exists())
        self.assertEqual((self.home / "audio-writes").read_text().strip(), "set-volume @DEFAULT_AUDIO_SINK@ 65%")
        row("Do Not Disturb").set_active(True)
        until(lambda: controls.dnd())
        (self.home / "dnd").unlink()
        until(lambda: not row("Do Not Disturb").get_active())
        row("Mute microphone").set_active(False)
        until(lambda: (self.home / "audio-writes").exists())
        self.assertIn("set-mute @DEFAULT_AUDIO_SOURCE@ 0", (self.home / "audio-writes").read_text())
        self.command("wpctl", "exit 2")
        window.refresh()
        until(lambda: not row("Output volume").get_sensitive())
        self.assertTrue(row("Do Not Disturb").get_sensitive())

        # Close the window during capture and stop from a freshly opened one.
        self.mock_recorder("gpu-screen-recorder")
        from gi.repository import Gio
        from unittest.mock import Mock
        folder = self.home / "recorded clips"
        folder.mkdir()
        window.tabs.set_visible_child_name("display")
        group = window.recording
        dialog = Mock()
        dialog.select_folder_finish.return_value = Gio.File.new_for_path(str(folder))
        group.folder_selected(dialog, None)
        self.assertEqual(controls.recording_directory(), folder)
        group.area.set_selected(2)
        group.audio.set_active(True)
        group.button.emit("clicked")
        until(lambda: group.recorder.phase == "sharing" and (self.home / "recorder-args").exists())
        self.assertFalse(group.button.get_sensitive())
        (self.home / "portal-approved").touch()
        until(lambda: group.recorder.phase == "recording" and (self.home / "recorder-args").exists())
        window.close()
        window = settings.Settings(app, group.recorder)
        self.addCleanup(window.close)
        window.present()
        self.assertEqual(window.tabs.get_visible_child_name(), "display")
        self.assertEqual(window.recording.button.get_label(), "Stop recording")
        self.assertEqual(window.recording.area.get_selected(), 2)
        self.assertTrue(window.recording.audio.get_active())
        until(lambda: row("Keep awake").get_active())
        row("Keep awake").set_active(False)
        self.assertFalse(app.keep_awake.enabled())
        window.recording.button.emit("clicked")
        until(lambda: group.recorder.phase == "idle")
        self.assertEqual(group.recorder.output.read_bytes(), b"finalized")
        self.assertEqual(callback_errors, [])


if __name__ == "__main__":
    unittest.main()
