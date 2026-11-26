"""Search the keybindings registered with the running Hyprland instance."""
import json

import gi
gi.require_version("Adw", "1")
gi.require_version("Gtk", "4.0")
from gi.repository import Adw, Gtk

from desktop_controls import run


MODIFIERS = ((64, "Super"), (4, "Ctrl"), (8, "Alt"), (1, "Shift"),
             (2, "Caps Lock"), (16, "Mod2"), (32, "Mod3"), (128, "Mod5"))
KEY_NAMES = {"Return": "Enter", "escape": "Esc", "grave": "`", "Print": "Print Screen",
             "mouse:272": "Left mouse button", "mouse:273": "Right mouse button",
             "mouse_down": "Scroll down", "mouse_up": "Scroll up"}
SEARCH_KEYS = {key.casefold(): name.casefold() for key, name in KEY_NAMES.items()}
SEARCH_KEYS.update(win="super", control="ctrl")


def read_bindings():
    bindings = json.loads(run("hyprctl", "-j", "binds"))
    if not isinstance(bindings, list):
        raise ValueError("Unexpected response from hyprctl binds")
    entries = []
    for bind in bindings:
        if not isinstance(bind, dict):
            raise ValueError("Expected a keybinding object from Hyprland")
        mask = bind.get("modmask", 0)
        keys = [name for bit, name in MODIFIERS if mask & bit]
        key = bind.get("key") or (f"Keycode {bind['keycode']}" if bind.get("keycode") else "Any key")
        keys.append(KEY_NAMES.get(key, key))
        chord = " + ".join(keys)
        dispatcher = bind.get("dispatcher", "")
        action = bind.get("description")
        if not action:
            if dispatcher.startswith("function:"):
                action = "Lua callback"
            elif dispatcher.startswith("HL.Dispatcher("):
                action = dispatcher.removeprefix("HL.Dispatcher(").removesuffix(")")
            else:
                action = f"{dispatcher} {bind.get('arg', '')}".strip() or "Unnamed action"
        if bind.get("release"):
            chord += " (on release)"
        if bind.get("longPress"):
            chord += " (long press)"
        universal = bind.get("submap_universal") in (True, "true")
        group = "All submaps" if universal else bind.get("submap") or "Global"
        entries.append((group, chord, action, key))
    return entries


class ShortcutsPage(Adw.PreferencesPage):
    def __init__(self):
        super().__init__()
        self.entries = None
        self.error = None
        self.groups = []
        self.rows = []
        header = Adw.PreferencesGroup()
        self.search = Gtk.SearchEntry(placeholder_text="Search keys, actions or submaps")
        self.search.connect("search-changed", lambda *_: self.filter_rows())
        header.add(self.search)
        self.message = Gtk.Label(wrap=True, label="Loading shortcuts…", css_classes=["dim-label"])
        header.add(self.message)
        self.add(header)

    def update_bindings(self, entries, error):
        self.error = error
        if error:
            entries = []
        if entries != self.entries:
            for group in self.groups:
                self.remove(group)
            self.groups.clear()
            self.rows.clear()
            self.entries = entries
            groups = {}
            for submap, chord, action, key in entries:
                if submap not in groups:
                    group = Adw.PreferencesGroup(title=submap)
                    groups[submap] = group
                    self.groups.append(group)
                    self.add(group)
                row = Adw.ActionRow(title=action, subtitle=chord, use_markup=False)
                groups[submap].add(row)
                self.rows.append((groups[submap], row, f"{chord} {key} {action} {submap}".casefold()))
        self.search.set_sensitive(not error)
        self.message.set_tooltip_text(error)
        self.filter_rows()

    def filter_rows(self):
        query = self.search.get_text().strip().casefold()
        terms = query.split()
        keys = None
        if "+" in query:
            parts = [part.strip() for part in query.split("+")]
            keys = {SEARCH_KEYS.get(part, part) for part in parts}
        visible = set()
        for group, row, text in self.rows:
            if keys is None:
                matches = all(term in text for term in terms)
            else:
                chord = row.get_subtitle().partition(" (")[0].casefold()
                matches = keys == set(chord.split(" + "))
            row.set_visible(matches)
            if matches:
                visible.add(group)
        for group in self.groups:
            group.set_visible(group in visible)
        self.message.set_visible(not visible)
        if self.error:
            self.message.set_text("Could not read shortcuts from Hyprland.")
        else:
            self.message.set_text("No matching shortcuts." if self.rows else "No registered shortcuts.")
