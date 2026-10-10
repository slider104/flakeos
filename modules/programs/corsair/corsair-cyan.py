#!/usr/bin/env python3
"""
Sets every LED on the Corsair Scimitar RGB Elite (1b1c:1be3) to one colour,
once, and exits.

This runs at boot and whenever the mouse is plugged in (see corsair.nix). It
is deliberately a one-shot: it sends four short commands and stops. It does
NOT poll, does NOT stay running, and does NOT hold the lighting handle open.
An earlier version did poll and repaint, to colour each DPI stage separately,
and that made the mouse reset itself to factory settings - the firmware
repaints the same LEDs in hardware mode, and the two writers fought. The
comments in corsair.nix have the full story. Do not reintroduce that.

What it does, in order:
  1. put lighting in SOFTWARE mode, so the host owns the LEDs and the mouse
     stops repainting them. This also disables the mouse's DPI stage cycling,
     which is why the DPI is then set explicitly below.
  2. pin the DPI, so pointer speed is the same after every boot instead of
     whatever stage the mouse happened to be on.
  3. write one LED frame, all zones the same colour.
  4. close up and exit.

Because software mode is volatile, none of this survives a power cycle, which
is exactly why it is wired to run again on boot and on replug.
"""

import fcntl
import os
import select
import struct
import sys
import time

# --- settings ---------------------------------------------------------------

# The colour for every LED, as R, G, B. 0x28 is the same dim level as the case
# fans in programs/openrgb/openrgb.nix, so the mouse matches the machine.
COLOUR = (0x00, 0x28, 0x28)

# Pointer speed, in DPI. The mouse's own stages were 400, 800, 1500, 3000 and
# 6000, but any value in range works since we set it directly. Cycling is off
# in software mode, so this is simply the DPI from now on.
DPI = 1500

# How long to wait for the mouse to appear before giving up. At boot the
# service can start before USB enumeration has finished.
WAIT_SECONDS = 30

# --- protocol ---------------------------------------------------------------

VID, PID = 0x1B1C, 0x1BE3
REPORT_SIZE = 128

MAGIC = 0x08
CMD_SET, CMD_CLOSE, CMD_WRITE, CMD_OPEN = 0x01, 0x05, 0x06, 0x0D

PROP_BRIGHTNESS = 0x02
PROP_MODE = 0x03
PROP_DPI_X = 0x21
PROP_DPI_Y = 0x22

MODE_SOFTWARE = 0x02

LIGHTING_HANDLE = 0x00
RES_LIGHTING = 0x0001

# Zone indices 0-7. Only four have LEDs on this mouse (0 logo, 1 wheel,
# 3 side buttons, 4 the stripe before the side pad); the others are accepted
# and ignored. The device derives the zone count from payload length / 3, so
# this stays at 8 unless the payload below is rebuilt to match.
ZONES = 8


def log(message):
    print(message, flush=True)


def find_device():
    """
    The mouse exposes four hidraw nodes. The Bragi command channel is the one
    whose report descriptor declares usage page 0xFF42 (06 42 ff) and a
    128-byte report (95 80). Matching on the descriptor rather than on a path
    means hidraw renumbering across boots cannot pick the wrong node.
    """
    base = "/sys/class/hidraw"
    try:
        names = sorted(os.listdir(base), key=lambda s: int(s[6:]))
    except OSError:
        return None
    for name in names:
        dev = f"{base}/{name}/device"
        try:
            with open(f"{dev}/uevent") as f:
                if "1BE3" not in f.read().upper():
                    continue
            with open(f"{dev}/report_descriptor", "rb") as f:
                desc = f.read()
        except OSError:
            continue
        if desc[:3] == b"\x06\x42\xff" and b"\x95\x80" in desc:
            return f"/dev/{name}"
    return None


def wait_for_device():
    deadline = time.monotonic() + WAIT_SECONDS
    while True:
        path = find_device()
        if path:
            return path
        if time.monotonic() >= deadline:
            return None
        time.sleep(1.0)


def xfer(fd, payload, what):
    pkt = bytearray(REPORT_SIZE + 1)  # [0] is the report id, always 0 here
    pkt[1] = MAGIC
    pkt[2 : 2 + len(payload)] = payload
    os.write(fd, bytes(pkt))
    if not select.select([fd], [], [], 1.0)[0]:
        raise RuntimeError(f"{what}: no reply from the mouse")
    reply = os.read(fd, REPORT_SIZE)
    if len(reply) < 3:
        raise RuntimeError(f"{what}: short reply ({len(reply)} bytes)")
    return reply


def set_prop(fd, prop, value, what):
    reply = xfer(fd, [CMD_SET, prop, 0x00, value & 0xFF, value >> 8], what)
    if reply[2]:
        raise RuntimeError(f"{what}: device returned error 0x{reply[2]:02X}")


def main():
    path = wait_for_device()
    if not path:
        log(f"Scimitar not found after {WAIT_SECONDS}s; nothing to do")
        return 0  # not an error: the mouse is simply not plugged in

    try:
        fd = os.open(path, os.O_RDWR)
    except OSError as e:
        log(f"cannot open {path}: {e}")
        return 1

    try:
        info = fcntl.ioctl(fd, 0x80084803, bytes(8))  # HIDIOCGRAWINFO
        _bus, vendor, product = struct.unpack("ihh", info)
        if (vendor & 0xFFFF, product & 0xFFFF) != (VID, PID):
            log(f"{path} is not {VID:04x}:{PID:04x}; refusing to write to it")
            return 1

        set_prop(fd, PROP_MODE, MODE_SOFTWARE, "set software lighting mode")
        set_prop(fd, PROP_DPI_X, DPI, "set DPI X")
        set_prop(fd, PROP_DPI_Y, DPI, "set DPI Y")

        # A handle left open by an earlier run makes the open fail with 0x03,
        # so close it first and ignore whatever that returns.
        try:
            xfer(fd, [CMD_CLOSE, LIGHTING_HANDLE], "pre-emptive close")
        except RuntimeError:
            pass

        reply = xfer(
            fd,
            [CMD_OPEN, LIGHTING_HANDLE, RES_LIGHTING & 0xFF, RES_LIGHTING >> 8],
            "open lighting handle",
        )
        if reply[2]:
            raise RuntimeError(
                f"open lighting handle: device returned error 0x{reply[2]:02X}"
            )

        try:
            r, g, b = COLOUR
            # planar: all red bytes, then all green, then all blue
            payload = bytes([r] * ZONES) + bytes([g] * ZONES) + bytes([b] * ZONES)

            pkt = bytearray(REPORT_SIZE + 1)
            pkt[1] = MAGIC
            pkt[2] = CMD_WRITE
            pkt[3] = LIGHTING_HANDLE
            pkt[4:8] = struct.pack("<I", len(payload))
            pkt[8 : 8 + len(payload)] = payload
            os.write(fd, bytes(pkt))
            if not select.select([fd], [], [], 1.0)[0]:
                raise RuntimeError("frame write: no reply from the mouse")
            reply = os.read(fd, REPORT_SIZE)
            if len(reply) >= 3 and reply[2]:
                raise RuntimeError(f"frame write: error 0x{reply[2]:02X}")

            set_prop(fd, PROP_BRIGHTNESS, 1000, "set brightness")
        finally:
            try:
                xfer(fd, [CMD_CLOSE, LIGHTING_HANDLE], "close lighting handle")
            except RuntimeError:
                pass

        log(
            f"Scimitar on {path}: all LEDs #{COLOUR[0]:02X}{COLOUR[1]:02X}"
            f"{COLOUR[2]:02X}, DPI {DPI}"
        )
        return 0
    except RuntimeError as e:
        log(str(e))
        return 1
    finally:
        try:
            os.close(fd)
        except OSError:
            pass


if __name__ == "__main__":
    sys.exit(main())
