"""Screen recording controls for the Settings application."""
from datetime import datetime
import os
from pathlib import Path
import shutil
import signal
import tempfile

import gi
gi.require_version("Adw", "1")
gi.require_version("Gtk", "4.0")
from gi.repository import Adw, Gio, GLib, GObject, Gtk

import desktop_controls as controls

MONITOR = "This monitor"
REGION = "Select a region"
PORTAL = "Choose a workspace or window"
AREAS = (MONITOR, REGION, PORTAL)


class Recorder(GObject.Object):
    """Own the child process across Settings window closes and reopens."""
    __gsignals__ = {"changed": (GObject.SignalFlags.RUN_FIRST, None, ())}

    def __init__(self, application):
        super().__init__()
        self.app = application
        application.connect("shutdown", lambda *_: self.stop())
        self.process = None
        self.phase = "idle"
        self.message = ""
        self.output = None
        self.area = MONITOR
        self.audio = False
        self.portal_watch = 0

    def start(self, folder, audio, monitor=None, *, portal=False):
        if self.phase != "idle":
            return
        self.app.hold()
        self.output = None
        self.audio = audio
        try:
            if portal:
                self.area = PORTAL
                args = ["gpu-screen-recorder", "-w", "portal", "-restore-portal-session", "no",
                        "-k", "h264", "-fallback-cpu-encoding", "yes", "-v", "no"]
                if audio:
                    args.extend(["-a", "default_output"])
                self.capture(folder, [*args, "-o"])
                return
            if monitor is not None:
                self.area = MONITOR
                self.capture_direct(folder, ["-o", monitor])
                return
            self.area = REGION
            self.process = Gio.Subprocess.new(["slurp"], Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE)
            self.phase = "selecting"
            self.message = "Drag a region on one monitor. Press Escape to cancel."
            self.emit("changed")
            self.process.communicate_utf8_async(None, None, self.region_selected, folder)
        except (OSError, ValueError, GLib.Error) as err:
            self.finish(str(err), failed=True)

    def region_selected(self, selector, result, folder):
        try:
            _, geometry, error = selector.communicate_utf8_finish(result)
            if not selector.get_successful() or not geometry.strip():
                if self.phase == "stopping" or not error.strip() or "cancel" in error.lower():
                    self.finish("")
                else:
                    self.finish(error.strip(), failed=True)
                return
            if self.phase == "stopping":
                self.finish("")
                return
            self.capture_direct(folder, ["-g", geometry.strip()])
        except (OSError, ValueError, GLib.Error) as err:
            self.finish(str(err), failed=True)

    def capture_direct(self, folder, target):
        args = ["wf-recorder", *target, "-y"]
        if self.audio:
            args.append("--audio")
        self.capture(folder, [*args, "-f"])

    def capture(self, folder, args):
        folder.mkdir(parents=True, exist_ok=True)
        # Reserve a unique private MP4 for this recording.
        stamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        with tempfile.NamedTemporaryFile(dir=folder, prefix=f"Recording-{stamp}-", suffix=".mp4", delete=False) as file:
            self.output = Path(file.name)

        # Keep stderr off the UI thread and retain diagnostics if the encoder fails.
        log = tempfile.TemporaryFile()
        try:
            launcher = Gio.SubprocessLauncher.new(Gio.SubprocessFlags.STDOUT_SILENCE)
            launcher.take_stderr_fd(os.dup(log.fileno()))
            self.process = launcher.spawnv([*args, str(self.output)])
        except BaseException:
            log.close()
            raise
        if self.area == PORTAL:
            self.phase = "sharing"
            self.message = "Choose a workspace or window, or cancel in the Hyprland sharing dialog."
            self.portal_watch = GLib.timeout_add(250, self.check_portal_capture)
        else:
            self.phase = "recording"
            self.message = str(self.output)
        self.process.wait_async(None, self.finished_capture, log)
        self.emit("changed")

    def output_started(self):
        try:
            return self.output.stat().st_size > 0
        except OSError:
            return False

    def check_portal_capture(self):
        # The encoder writes the MP4 header only after the portal grants a source.
        if self.phase == "sharing" and self.output_started():
            self.phase = "recording"
            self.message = str(self.output)
            self.emit("changed")
        if self.phase == "sharing":
            return GLib.SOURCE_CONTINUE
        self.portal_watch = 0
        return GLib.SOURCE_REMOVE

    def stop(self):
        if self.phase not in ("recording", "selecting", "sharing"):
            return
        previous = self.phase
        self.phase = "stopping"
        # A recorder blocked in the portal picker cannot handle SIGINT until
        # selection returns. This path is used on application shutdown.
        if previous == "sharing" and not self.output_started():
            self.process.force_exit()
            self.process.wait(None)
            # The main loop may exit before finished_capture runs on shutdown.
            try:
                if self.output.stat().st_size == 0:
                    self.output.unlink()
            except OSError:
                pass
        else:
            self.process.send_signal(signal.SIGTERM if previous == "selecting" else signal.SIGINT)
        self.emit("changed")

    def finished_capture(self, process, result, log):
        with log:
            try:
                process.wait_finish(result)
                try:
                    size = self.output.stat().st_size
                except FileNotFoundError:
                    size = 0
                if process.get_successful() and size:
                    self.finish(f"Saved to {self.output}")
                    return
                end = log.seek(0, os.SEEK_END)
                log.seek(max(0, end - 2048))
                lines = log.read().decode(errors="replace").strip().splitlines()
                if self.area == PORTAL and not size:
                    if self.phase == "stopping" or any("cancel" in line.lower() for line in lines):
                        self.finish("Source selection cancelled.", failed=True)
                        return
                detail = lines[-1] if lines else "The recorder produced no video."
                self.finish(f"Recording failed. {detail}", failed=True)
            except (OSError, GLib.Error) as err:
                self.finish(str(err), failed=True)

    def finish(self, message, failed=False):
        try:
            if self.portal_watch:
                GLib.source_remove(self.portal_watch)
                self.portal_watch = 0
            if failed and self.output is not None:
                try:
                    if self.output.stat().st_size == 0:
                        self.output.unlink()
                    else:
                        message += f" Partial file at {self.output}"
                except OSError:
                    pass
            self.process = None
            self.phase = "idle"
            self.message = message
            self.emit("changed")
            if message and not self.app.get_windows():
                notice = Gio.Notification.new("Screen recording")
                notice.set_body(message)
                self.app.send_notification("screen-recording", notice)
        finally:
            self.app.release()


class RecordingGroup(Adw.PreferencesGroup):
    def __init__(self, window, recorder):
        super().__init__(title="Screen recording")
        self.window = window
        self.recorder = recorder
        self.folder = None
        self.destination = Adw.ActionRow(title="Save recordings to", activatable=True, use_markup=False)
        self.destination.add_suffix(Gtk.Image.new_from_icon_name("folder-open-symbolic"))
        self.destination.connect("activated", self.choose_folder)
        self.add(self.destination)
        try:
            self.set_folder(controls.recording_directory())
        except (OSError, ValueError) as err:
            self.destination.set_subtitle(str(err))

        self.area = Adw.ComboRow(title="Capture area", model=Gtk.StringList.new(AREAS))
        self.audio = Adw.SwitchRow(title="Include audio")
        self.add(self.area)
        self.add(self.audio)
        self.status = Adw.ActionRow(use_markup=False)
        self.button = Gtk.Button(valign=Gtk.Align.CENTER)
        self.button.connect("clicked", self.clicked)
        self.status.add_suffix(self.button)
        self.status.set_activatable_widget(self.button)
        self.add(self.status)
        self.handler = recorder.connect("changed", self.update)
        self.area.connect("notify::selected", self.update)
        self.update()

    def set_folder(self, folder):
        self.folder = folder
        self.destination.set_subtitle(str(folder))

    def choose_folder(self, *_):
        dialog = Gtk.FileDialog(title="Choose a recording folder")
        if self.folder and self.folder.is_dir():
            dialog.set_initial_folder(Gio.File.new_for_path(str(self.folder)))
        dialog.select_folder(self.window, None, self.folder_selected)

    def folder_selected(self, dialog, result):
        try:
            path = dialog.select_folder_finish(result).get_path()
            if not path:
                raise ValueError("Choose a local recording folder")
            controls.save_preference("recording_directory", path)
            self.set_folder(Path(path))
            self.update()
        except GLib.Error as err:
            if not err.matches(Gtk.DialogError.quark(), Gtk.DialogError.DISMISSED):
                self.status.set_subtitle(str(err))
        except (OSError, ValueError) as err:
            self.status.set_subtitle(str(err))

    def clicked(self, *_):
        if self.recorder.phase != "idle":
            self.recorder.stop()
            return
        output = None
        area = AREAS[self.area.get_selected()]
        if area == MONITOR:
            monitor = self.window.get_display().get_monitor_at_surface(self.window.get_surface())
            output = monitor.get_connector() if monitor else None
            if not output:
                self.status.set_subtitle("Could not identify this monitor. Choose Select a region.")
                return
        self.recorder.start(self.folder, self.audio.get_active(), output, portal=area == PORTAL)

    def update(self, *_):
        phase = self.recorder.phase
        idle = phase == "idle"
        if not idle:
            selected = AREAS.index(self.recorder.area)
            if self.area.get_selected() != selected:
                self.area.set_selected(selected)
            self.audio.set_active(self.recorder.audio)
        for row in (self.destination, self.area, self.audio):
            row.set_sensitive(idle)
        title, label = {
            "idle": ("Ready to record", "Start recording"),
            "selecting": ("Select a region", "Cancel"),
            "sharing": ("Waiting for a source", "Waiting…"),
            "recording": ("Recording", "Stop recording"),
            "stopping": ("Finishing", "Please wait"),
        }[phase]
        program = "gpu-screen-recorder" if AREAS[self.area.get_selected()] == PORTAL else "wf-recorder"
        available = shutil.which(program) is not None
        self.status.set_title(title)
        self.status.set_subtitle(self.recorder.message if available or not idle else f"Install {program} for this capture mode.")
        self.button.set_label(label)
        self.button.set_css_classes(["suggested-action" if idle else "destructive-action"])
        self.button.set_sensitive(phase not in ("sharing", "stopping") and (not idle or (available and self.folder is not None)))
