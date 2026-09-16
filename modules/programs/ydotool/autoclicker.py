#!/usr/bin/env python3
"""Autoclicker: a small window on top of ydotool.

How it works: ydotool does the actual clicking. `ydotool click --repeat N
--next-delay D 0xC0` clicks the left button N times. The Start button runs
that command, Stop (or closing the window) kills it. Nothing clicks until you
press Start or the start/stop key.

The start/stop key: on Wayland an app only sees keys while its own window
has focus. So the window reads the keyboards and mice directly, from
/dev/input (python-evdev; your user needs the `input` group). That way the
key works in every window, even in fullscreen games, as long as this window
is open. The key still reaches the focused app too, so pick one nothing else
uses.

Every change in the window is saved right away, to
~/.config/autoclicker/settings.json, and loaded the next time it opens.
"""

import json
import os
import signal
import subprocess
import sys
import time
from pathlib import Path

import evdev
import gi
from evdev import ecodes

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, GLib, Gtk  # noqa: E402

APP_ID = "org.flakeos.Autoclicker"

SETTINGS_FILE = (
    Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    / "autoclicker"
    / "settings.json"
)

DEFAULTS = {
    "cps": 20,  # clicks per second
    "button": "left",
    "count": 0,  # 0 = until you stop it
    "delay": 3,  # seconds between pressing Start and the first click
    "key": None,  # start/stop key: an evdev key code, like 66 for F8
}

# ydotool button codes: the low bits pick the button, 0x40 = press,
# 0x80 = release, so 0xC0 = press + release of the left button.
BUTTONS = {"left": 0x00, "right": 0x01, "middle": 0x02}
PRESS = 0x40
RELEASE = 0x80

# ydotool waits --next-delay milliseconds after the press AND after the
# release, in whole milliseconds. 1 ms + 1 ms = 500 clicks per second.
MAX_CPS = 500
FOREVER = 2_000_000_000  # --repeat for "until you stop it"

# Nicer names for mouse buttons. Keys are named after their evdev name.
MOUSE_BUTTON_NAMES = {
    ecodes.BTN_RIGHT: "Right mouse button",
    ecodes.BTN_MIDDLE: "Middle mouse button",
    ecodes.BTN_SIDE: "Mouse side button (back)",
    ecodes.BTN_EXTRA: "Mouse extra button (forward)",
}


def load_settings():
    settings = dict(DEFAULTS)
    try:
        settings.update(json.loads(SETTINGS_FILE.read_text()))
    except (OSError, ValueError):
        pass  # no file yet, or broken: use the defaults
    if settings["button"] not in BUTTONS:
        settings["button"] = DEFAULTS["button"]
    settings["cps"] = min(max(int(settings["cps"]), 1), MAX_CPS)
    return settings


def save_settings(settings):
    SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    SETTINGS_FILE.write_text(json.dumps(settings, indent=2) + "\n")


def daemon_problem():
    """Why ydotool can't click right now, or None if it can."""
    if os.access(os.environ.get("YDOTOOL_SOCKET", ""), os.W_OK):
        return None
    return (
        "Can't reach ydotoold. Is your user in the ydotool group? "
        "After adding it, log out and back in."
    )


def key_name(code):
    if code in MOUSE_BUTTON_NAMES:
        return MOUSE_BUTTON_NAMES[code]
    names = ecodes.bytype[ecodes.EV_KEY].get(code, f"KEY_{code}")
    name = names[0] if isinstance(names, (list, tuple)) else names
    name = name.split("_", 1)[-1].replace("_", " ")  # KEY_LEFTSHIFT -> LEFTSHIFT
    return name if len(name) <= 3 else name.capitalize()  # F8, A, Leftshift


class KeyListener:
    """Watches every keyboard and mouse in /dev/input and calls
    on_press(code, time) for each key or button press, whichever window has
    focus. Runs inside GTK's main loop, so no threads."""

    def __init__(self, on_press):
        self.on_press = on_press
        self.devices = {}  # path -> (device, GLib watch), or None = not a keyboard/mouse
        self.can_read = False
        self.rescan()
        # Pick up keyboards and mice plugged in while the window is open.
        GLib.timeout_add_seconds(2, self.rescan)

    def rescan(self):
        paths = evdev.list_devices()  # only the ones we're allowed to read
        self.can_read = bool(paths)
        for path in set(self.devices) - set(paths):
            self.forget(path)
        for path in paths:
            if path in self.devices:
                continue
            try:
                device = evdev.InputDevice(path)
            except OSError:
                continue  # gone again already
            # Skip devices without keys/buttons, and ydotool's own fake
            # mouse: its clicks must never count as the start/stop key.
            if "ydotoold" in device.name or ecodes.EV_KEY not in device.capabilities():
                device.close()
                self.devices[path] = None
                continue
            watch = GLib.io_add_watch(
                device.fd,
                GLib.PRIORITY_DEFAULT,
                GLib.IOCondition.IN | GLib.IOCondition.HUP | GLib.IOCondition.ERR,
                self.on_ready,
                path,
            )
            self.devices[path] = (device, watch)
        return GLib.SOURCE_CONTINUE

    def forget(self, path, remove_watch=True):
        entry = self.devices.pop(path, None)
        if entry:
            device, watch = entry
            if remove_watch:
                GLib.source_remove(watch)
            device.close()

    def on_ready(self, _fd, _condition, path):
        device, _watch = self.devices[path]
        try:
            for event in device.read():
                if event.type == ecodes.EV_KEY and event.value == 1:  # 1 = pressed
                    self.on_press(event.code, event.timestamp())
        except BlockingIOError:
            pass  # nothing more to read right now
        except OSError:
            self.forget(path, remove_watch=False)  # unplugged
            return GLib.SOURCE_REMOVE
        return GLib.SOURCE_CONTINUE


class Window(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title="Autoclicker")
        self.set_default_size(420, -1)
        self.settings = load_settings()
        self.clicker = None  # the running `sleep; ydotool click` process
        self.capturing_since = None  # time "Set" was pressed, while waiting for a key

        def spin_row(key, title, subtitle, lowest, highest):
            row = Adw.SpinRow.new_with_range(lowest, highest, 1)
            row.set_title(title)
            row.set_subtitle(subtitle)
            row.set_value(self.settings[key])
            row.connect("notify::value", lambda r, _: self.save(key, int(r.get_value())))
            return row

        names = list(BUTTONS)
        button_row = Adw.ComboRow(
            title="Mouse button",
            model=Gtk.StringList.new([name.capitalize() for name in names]),
            selected=names.index(self.settings["button"]),
        )
        button_row.connect("notify::selected", lambda r, _: self.save("button", names[r.get_selected()]))

        clicking = Adw.PreferencesGroup()
        clicking.add(spin_row("cps", "Clicks per second", f"1 to {MAX_CPS}", 1, MAX_CPS))
        clicking.add(button_row)
        clicking.add(spin_row("count", "Number of clicks", "0 = until you stop it", 0, 1_000_000))
        clicking.add(spin_row("delay", "Start delay", "Seconds to move the mouse to the target first", 0, 60))

        self.set_key_button = Gtk.Button(valign=Gtk.Align.CENTER)
        self.set_key_button.connect("clicked", self.on_set_key)
        clear_key_button = Gtk.Button(
            icon_name="edit-clear-symbolic",
            tooltip_text="No key",
            valign=Gtk.Align.CENTER,
            css_classes=["flat"],
        )
        clear_key_button.connect("clicked", lambda _: self.save("key", None))
        self.key_row = Adw.ActionRow(title="Start/stop key")
        self.key_row.add_suffix(self.set_key_button)
        self.key_row.add_suffix(clear_key_button)

        hotkey = Adw.PreferencesGroup(
            description="Works in every window while this one is open, and "
            "starts without the delay. The key still reaches the app you're "
            "in, so pick one nothing else uses (like F8 or a mouse side button)."
        )
        hotkey.add(self.key_row)

        self.toggle_button = Gtk.Button(halign=Gtk.Align.CENTER, css_classes=["pill"])
        self.toggle_button.connect("clicked", lambda _: self.toggle(self.settings["delay"]))

        hint = Gtk.Label(
            label="Closing this window stops it too.",
            css_classes=["dim-label", "caption"],
        )

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=18)
        for side in ("top", "bottom", "start", "end"):
            getattr(box, f"set_margin_{side}")(18)
        box.append(clicking)
        box.append(hotkey)
        box.append(self.toggle_button)
        box.append(hint)

        self.toasts = Adw.ToastOverlay(child=box)
        view = Adw.ToolbarView(content=self.toasts)
        view.add_top_bar(Adw.HeaderBar())
        self.set_content(view)

        self.connect("close-request", lambda _: self.stop())
        self.listener = KeyListener(self.on_key_press)

        # With a number of clicks set, the clicker finishes on its own:
        # check a few times per second so the button goes back to "Start".
        self.update()
        GLib.timeout_add(200, self.update)

    def running(self):
        return self.clicker is not None and self.clicker.poll() is None

    def start(self, delay):
        button = BUTTONS[self.settings["button"]]
        half_click_ms = max(1, round(1000 / self.settings["cps"] / 2))
        click = [
            "ydotool", "click",
            "--repeat", str(self.settings["count"] or FOREVER),
            "--next-delay", str(half_click_ms),
            hex(PRESS | RELEASE | button),
        ]
        # `sleep`, then become ydotool. start_new_session: the sleep and
        # ydotool form their own process group, so stop() can kill both.
        self.clicker = subprocess.Popen(
            ["/bin/sh", "-c", 'sleep "$0" && exec "$@"', str(delay), *click],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.clicker_button = button

    def stop(self):
        clicker = self.clicker
        if clicker is None or clicker.poll() is not None:
            return  # not running
        os.killpg(clicker.pid, signal.SIGTERM)
        clicker.wait()
        # If it was killed between press and release, the button would stay
        # held down: release it.
        subprocess.run(
            ["ydotool", "click", hex(RELEASE | self.clicker_button)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def toggle(self, delay):
        if self.running():
            self.stop()
        elif problem := daemon_problem():
            self.toasts.add_toast(Adw.Toast(title=problem, timeout=8))
        else:
            self.start(delay)
        self.update()

    def save(self, key, value):
        self.settings[key] = value
        save_settings(self.settings)
        self.update()

    def on_set_key(self, _button):
        self.capturing_since = time.time()
        self.update()

    def on_key_press(self, code, pressed_at):
        if self.capturing_since is not None:
            # Ignore the key/click that pressed "Set" itself, and the left
            # mouse button: you need that one to use the window.
            if pressed_at < self.capturing_since or code == ecodes.BTN_LEFT:
                return
            self.capturing_since = None
            if code == ecodes.KEY_ESC:
                self.update()  # Escape = cancel, keep the old key
            else:
                self.save("key", code)
        elif code == self.settings["key"]:
            self.toggle(0)

    def update(self):
        if self.running():
            label, on, off = "Stop", "destructive-action", "suggested-action"
        else:
            label, on, off = "Start", "suggested-action", "destructive-action"
        self.toggle_button.set_label(label)
        self.toggle_button.add_css_class(on)
        self.toggle_button.remove_css_class(off)

        if not self.listener.can_read:
            self.key_row.set_subtitle("Can't read keyboards: is your user in the input group?")
        elif self.capturing_since is not None:
            self.key_row.set_subtitle("Press a key or mouse button (Escape: cancel)")
        elif self.settings["key"] is None:
            self.key_row.set_subtitle("None")
        else:
            self.key_row.set_subtitle(key_name(self.settings["key"]))
        self.set_key_button.set_label("Waiting…" if self.capturing_since is not None else "Set")
        return GLib.SOURCE_CONTINUE


def main():
    app = Adw.Application(application_id=APP_ID)
    # Opening it again brings the open window to the front.
    app.connect("activate", lambda app: (app.get_active_window() or Window(app)).present())
    sys.exit(app.run(sys.argv))


if __name__ == "__main__":
    main()
