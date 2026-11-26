#!/usr/bin/env python3
"""Hypr Dots Settings. Run directly or from the desktop launcher."""
from concurrent.futures import ThreadPoolExecutor
from functools import partial
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gdk, GdkPixbuf, GLib, Gtk

import desktop_controls as controls
from recording import Recorder, RecordingGroup
import theme

ERRORS = (OSError, ValueError, TypeError, KeyError, IndexError, RuntimeError, subprocess.SubprocessError, GLib.Error)


def theme_preview(name):
    if not theme.ID.fullmatch(name):
        raise ValueError("Invalid theme ID")
    manifest = theme.read_toml(theme.THEMES / name / "theme.toml")
    palette = {role: manifest["palette"][role] for role in ("base", "crust", "blue", "lavender", "green")}
    theme.check_values(palette)
    style = theme.read_toml(theme.THEMES / "defaults.toml") | manifest.get("style", {})
    # Use the published artwork, including a user's original Mocha lock image.
    image = theme.ACTIVE / "wallpapers/0.png"
    if not image.is_file():
        image = Path.home() / "Pictures/wallpapers/bg1.jpg"
    pixbuf = None
    if image.is_file():
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(str(image), 800, 320, True)
        except GLib.Error:
            pass
    return palette, pixbuf, style["variant"]


class KeepAwake:
    def __init__(self, app):
        self.app = app
        self.lock = None
        self.pending = False

    def enabled(self):
        return self.pending or self.lock is not None

    def change(self, enabled, window):
        if window.updating or self.pending or enabled == self.enabled():
            return
        if enabled:
            self.pending = True
            self.app.hold()
            window.keep_awake.set_sensitive(False)
            future = window.worker.submit(controls.acquire_idle_inhibitor)
            future.add_done_callback(lambda done: GLib.idle_add(self.acquired, done, window))
        else:
            self.lock = None
            self.app.release()

    def acquired(self, future, window):
        self.pending = False
        try:
            self.lock = future.result()
        except ERRORS as error:
            self.app.release()
            if not window.closed:
                window.overlay.add_toast(Adw.Toast(title=str(error)[:240], use_markup=False))
        if not window.closed:
            window.refresh()
        return False


class Settings(Adw.ApplicationWindow):
    def __init__(self, application, recorder):
        super().__init__(application=application, title="Settings",
                         default_width=690, default_height=640)
        self.worker = ThreadPoolExecutor(max_workers=1)
        self.reading = self.updating = self.closed = False
        self.pending_writes = 0
        self.revision = 0
        self.debounce = {}
        self.readers = {}
        self.theme_names = theme.theme_names()
        self.preview_key = None
        self.preview_data = None
        self.previous = None

        self.tabs = Adw.ViewStack()
        header = Adw.HeaderBar()
        header.set_title_widget(Adw.ViewSwitcher(stack=self.tabs))
        toolbar = Adw.ToolbarView()
        toolbar.add_top_bar(header)
        self.overlay = Adw.ToastOverlay(child=self.tabs)
        toolbar.set_content(self.overlay)
        self.set_content(toolbar)

        page = self.page("appearance", "Appearance", "applications-graphics-symbolic")
        appearance = self.group(page, "Desktop")
        self.preview = Gtk.DrawingArea(content_height=138, accessible_role=Gtk.AccessibleRole.IMG)
        self.preview.update_property([Gtk.AccessibleProperty.LABEL], ["Theme and bar position preview"])
        self.preview.set_draw_func(self.draw_preview)
        self.preview.add_css_class("card")
        appearance.add(self.preview)
        self.choice(appearance, "Theme", self.theme_names, theme.selected, self.apply_theme)
        self.choice(appearance, "Bar position", controls.EDGES, controls.edge,
                    lambda edge: controls.run(controls.SCRIPTS / "waybar-position.sh", edge))
        self.restore = self.button_row(appearance, "Restore previous theme", "edit-undo-symbolic",
                                       lambda: self.apply_theme(self.previous))
        self.restore.set_visible(False)
        self.readers["previous"] = (page, controls.previous_theme, self.show_previous, self.restore)
        wallpaper = self.group(page, "Wallpaper")
        self.wall_row = Adw.ActionRow(title="Wallpaper rotation")
        for label, icon, action in (("Previous wallpaper", "go-previous-symbolic", "previous"),
                                    ("Next wallpaper", "go-next-symbolic", "next")):
            button = Gtk.Button(icon_name=icon, tooltip_text=label, valign=Gtk.Align.CENTER)
            button.connect("clicked", lambda _, cmd=action: self.apply(partial(controls.run, "wpaperctl", cmd)))
            self.wall_row.add_suffix(button)
        wallpaper.add(self.wall_row)
        self.readers["wallpaper"] = (page, partial(controls.run, "wpaperctl", "get-status"), lambda _: None, self.wall_row)

        page = self.page("display", "Display", "video-display-symbolic")
        screen = self.group(page, "Screen")
        self.slider(screen, "Brightness", controls.brightness, 1,
                    lambda n: controls.run("brightnessctl", "-c", "backlight", "set", f"{n}%"))
        keep_awake = application.keep_awake
        self.keep_awake = Adw.SwitchRow(title="Keep awake", subtitle="Pause automatic locking, screen-off and suspend")
        screen.add(self.keep_awake)
        self.keep_awake.connect("notify::active", lambda row, _: keep_awake.change(row.get_active(), self))
        self.register(screen, "Keep awake", self.keep_awake, keep_awake.enabled, self.keep_awake.set_active)
        night = self.group(page, "Night light")
        self.switch(night, "Night light now", controls.night_light,
                    lambda on: controls.run(controls.SCRIPTS / "hyprsunset-toggle.sh", "on" if on else "off"))
        self.switch(night, "Start enabled at login", controls.night_login, controls.save_night_login)
        self.recording = RecordingGroup(self, recorder)
        page.add(self.recording)

        page = self.page("sound", "Sound & notifications", "audio-volume-high-symbolic")
        audio = self.group(page, "Audio")
        self.slider(audio, "Output volume", controls.volume, 0,
                    lambda n: controls.run("wpctl", "set-volume", controls.SINK, f"{n}%"))
        self.switch(audio, "Mute microphone", controls.microphone_muted,
                    lambda on: controls.run("wpctl", "set-mute", controls.SOURCE, "1" if on else "0"))
        notifications = self.group(page, "Notifications")
        self.switch(notifications, "Do Not Disturb", controls.dnd,
                    lambda on: controls.run(controls.SCRIPTS / "mako-dnd-toggle.sh", "on" if on else "off"))

        if recorder.phase != "idle":
            self.tabs.set_visible_child_name("display")
        self.tabs.connect("notify::visible-child", lambda *_: self.refresh())
        self.connect("close-request", self.close_window)
        self.timer = GLib.timeout_add_seconds(2, self.refresh)
        for _, _, _, row in self.readers.values():
            row.set_sensitive(False)
        self.refresh()

    def page(self, name, title, icon):
        page = Adw.PreferencesPage()
        self.tabs.add_titled_with_icon(page, name, title, icon)
        return page

    def group(self, page, title):
        group = Adw.PreferencesGroup(title=title)
        page.add(group)
        return group

    def register(self, group, key, row, read, show):
        self.readers[key] = (group.get_ancestor(Adw.PreferencesPage), read, show, row)

    def choice(self, group, title, choices, read, save):
        labels = [v.replace("-", " ").title() for v in choices]
        row = Adw.ComboRow(title=title, model=Gtk.StringList.new(labels))

        def changed(*_):
            i = row.get_selected()
            if i < len(choices):
                self.apply(partial(save, choices[i]))

        def show(value):
            row.set_selected(choices.index(value) if value in choices else Gtk.INVALID_LIST_POSITION)

        row.connect("notify::selected", changed)
        group.add(row)
        self.register(group, title, row, read, show)

    def switch(self, group, title, read, save):
        row = Adw.SwitchRow(title=title)
        row.connect("notify::active", lambda *_: self.apply(partial(save, row.get_active())))
        group.add(row)
        self.register(group, title, row, read, row.set_active)

    def slider(self, group, title, read, minimum, save):
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, minimum, 100, 1)
        scale.set_size_request(160, -1)
        scale.set_valign(Gtk.Align.CENTER)
        scale.update_property([Gtk.AccessibleProperty.LABEL], [title])
        row = Adw.ActionRow(title=title)
        row.add_suffix(scale)
        group.add(row)

        def changed(*_):
            if self.updating:
                return
            value = round(scale.get_value())
            row.set_subtitle(f"{value}%")
            if title in self.debounce:
                GLib.source_remove(self.debounce[title][0])
            operation = partial(save, value)

            def submit():
                self.debounce.pop(title, None)
                self.apply(operation)
                return False

            self.debounce[title] = GLib.timeout_add(200, submit), operation

        def show(value):
            # WirePlumber may already be amplified above 100% by another tool.
            scale.set_range(min(minimum, value), max(100, value))
            scale.set_value(value)
            row.set_subtitle(f"{value}%")

        scale.connect("value-changed", changed)
        self.register(group, title, row, read, show)

    def button_row(self, group, title, icon, action):
        row = Adw.ActionRow(title=title, activatable=True)
        row.add_suffix(Gtk.Image.new_from_icon_name(icon))
        row.connect("activated", lambda _: self.apply(action))
        group.add(row)
        return row

    def show_previous(self, name):
        self.previous = name
        self.restore.set_visible(bool(name))
        if name:
            self.restore.set_subtitle(name.replace("-", " ").title())

    def apply_theme(self, name):
        controls.run(controls.SCRIPTS / "theme.py", "use", name, timeout=90)

    def apply(self, operation):
        if self.updating or self.closed:
            return
        self.revision += 1
        self.pending_writes += 1
        self.tabs.set_sensitive(False)
        future = self.worker.submit(operation)
        future.add_done_callback(lambda done: GLib.idle_add(self.applied, done))

    def applied(self, future):
        if self.closed:
            return False
        self.pending_writes -= 1
        try:
            future.result()
        except ERRORS as error:
            self.overlay.add_toast(Adw.Toast(title=str(error)[:240], use_markup=False))
        self.tabs.set_sensitive(self.pending_writes == 0)
        self.refresh()
        return False

    def refresh(self):
        if self.closed or self.reading or self.pending_writes or self.debounce:
            return not self.closed
        page = self.tabs.get_visible_child()
        reads = {key: read for key, (owner, read, _, _) in self.readers.items() if owner == page}
        revision = self.revision
        self.reading = True

        def collect():
            values = {}
            for key, read in reads.items():
                try:
                    values[key] = (read(), None)
                except ERRORS as error:
                    values[key] = (None, str(error))
            return values

        future = self.worker.submit(collect)
        future.add_done_callback(lambda done: GLib.idle_add(self.render, done, page, revision))
        return True

    def render(self, future, page, revision):
        self.reading = False
        if self.closed:
            return False
        if page != self.tabs.get_visible_child() or revision != self.revision:
            self.refresh()
            return False
        self.updating = True
        try:
            values = future.result()
            for key, (value, error) in values.items():
                _, _, show, row = self.readers[key]
                if key in self.debounce:
                    continue
                if not error:
                    try:
                        show(value)
                    except ValueError as exc:
                        error = str(exc)
                row.set_sensitive(not error and not (row is self.keep_awake and self.get_application().keep_awake.pending))
                row.set_tooltip_text(error)
                if error:
                    row.set_subtitle("Unavailable")
                elif key not in ("Brightness", "Output volume", "Keep awake", "previous"):
                    row.set_subtitle("")
            if "Theme" in values:
                name, edge = values["Theme"][0], values["Bar position"][0]
                build = theme.ACTIVE.resolve()
                if self.preview_key != (build, name, edge):
                    if not self.preview_key or self.preview_key[:2] != (build, name):
                        try:
                            self.preview_data = theme_preview(name) if name else None
                        except ERRORS:
                            self.preview_data = None
                        if self.preview_data:
                            scheme = (Adw.ColorScheme.FORCE_DARK if self.preview_data[2] == "dark"
                                      else Adw.ColorScheme.FORCE_LIGHT)
                            self.get_application().get_style_manager().set_color_scheme(scheme)
                    self.preview_key = build, name, edge
                    self.preview.queue_draw()
        finally:
            self.updating = False
        return False

    def draw_preview(self, area, cr, width, height):
        if not self.preview_data:
            return
        palette, image, _ = self.preview_data

        def paint(role):
            color = Gdk.RGBA()
            if color.parse("#" + palette[role]):
                cr.set_source_rgb(color.red, color.green, color.blue)

        paint("base")
        cr.paint()
        if image:
            ratio = max(width / image.get_width(), height / image.get_height())
            cr.save()
            cr.translate((width - image.get_width() * ratio) / 2, (height - image.get_height() * ratio) / 2)
            cr.scale(ratio, ratio)
            Gdk.cairo_set_source_pixbuf(cr, image, 0, 0)
            cr.paint()
            cr.restore()
        edge = self.preview_key[2]
        if edge not in controls.EDGES:
            return
        vertical = edge in ("left", "right")
        x = width - 17 if edge == "right" else 7
        y = height - 17 if edge == "bottom" else 7
        length = (height if vertical else width) - 14
        paint("crust")
        cr.rectangle(x, y, 10 if vertical else length, length if vertical else 10)
        cr.fill()
        for offset, role in ((5, "blue"), (length / 2 - 8, "lavender"), (length - 20, "green")):
            paint(role)
            cr.rectangle(x + (3 if vertical else offset), y + (offset if vertical else 3),
                         4 if vertical else 15, 15 if vertical else 4)
            cr.fill()

    def close_window(self, *_):
        self.closed = True
        self.recording.recorder.disconnect(self.recording.handler)
        GLib.source_remove(self.timer)
        for handle, operation in self.debounce.values():
            GLib.source_remove(handle)
            self.worker.submit(operation)
        self.worker.shutdown(wait=False)
        return False


def main():
    app = Adw.Application(application_id="io.github.hyprdots.Settings")
    app.keep_awake = KeepAwake(app)
    recorder = Recorder(app)

    def activate(application):
        window = application.get_active_window() or Settings(application, recorder)
        window.present()

    app.connect("activate", activate)
    return app.run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
