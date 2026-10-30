# Hardware

Sound, Bluetooth, monitors, the graphics card, and the things that only exist
on one of the two machines: RGB lighting, the Corsair mouse's side buttons, the
data drive, the autoclicker.

Most of this is "it already works, here is what is behind it and how to check
it when it doesn't".

## Contents

- [Sound](#sound)
  - [Checking and changing devices](#checking-and-changing-devices)
  - [The microphone](#the-microphone)
- [Bluetooth](#bluetooth)
- [Monitors](#monitors)
- [The graphics card](#the-graphics-card)
- [Keyboard and mouse](#keyboard-and-mouse)
- [RGB lighting (zeus)](#rgb-lighting-zeus)
- [The Corsair mouse (zeus)](#the-corsair-mouse-zeus)
- [The be quiet! fan controller (zeus)](#the-be-quiet-fan-controller-zeus)
- [The autoclicker](#the-autoclicker)
- [The data drive (zeus)](#the-data-drive-zeus)
- [USB sticks and other drives](#usb-sticks-and-other-drives)
- [The keyboard-dead-after-reboot quirk (zeus)](#the-keyboard-dead-after-reboot-quirk-zeus)
- [Battery and power (hermes)](#battery-and-power-hermes)
- [Finding out what hardware you have](#finding-out-what-hardware-you-have)

---

## Sound

Sound goes through **PipeWire** (`modules/system/audio.nix`), which answers to
everything: ALSA, PulseAudio and JACK clients all work without knowing it is
PipeWire underneath. 32-bit support is on, which old games need.

Day to day you use noctalia's control center (click the right end of the bar)
to pick an output and set the volume, or the media keys. Volume is deliberately
capped at 100% — the key bind passes `-l 1.0`, so you cannot accidentally
distort by overdriving.

### Checking and changing devices

```sh
wpctl status
```

That lists everything: **Sinks** are outputs, **Sources** are inputs. The one
marked with a `*` is the default.

| command | does |
|---|---|
| `wpctl status` | the whole picture, with ID numbers |
| `wpctl set-default <ID>` | make a device the default |
| `wpctl get-volume @DEFAULT_AUDIO_SINK@` | current volume and mute state |
| `wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5` | set it to 50% |
| `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | mute / unmute |
| `wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1.0` | the microphone |

Nothing coming out at all? In order:

```sh
systemctl --user status pipewire wireplumber
```
```sh
systemctl --user restart pipewire pipewire-pulse wireplumber
```

That restart is per-user, so **no sudo**, and it is safe — it takes a second
and nothing else notices.

Does the kernel even see the card?

```sh
journalctl -k -b | grep -i "snd\|audio"
```

### The microphone

One thing worth writing down, because it looks like a bug and isn't:

**A microphone can be hardware-capped at PipeWire volume 1.00.** If your mic
is quiet and raising the volume past 100% in the control center does nothing
audible, that is the microphone's own preamp at its ceiling, not a
misconfiguration. `modules/system/audio.nix` is fine; there is no software
setting that will fix it.

The real fixes, in order of how well they work:

1. **Move it closer.** A dynamic mic 20 cm away is a different instrument
   from one 60 cm away.
2. **An external preamp or an audio interface.** This is what actually solves
   it.
3. **Per-application gain.** Some programs (OBS, Discord) have their own mic
   boost that works beyond PipeWire's.

Check what the hardware itself reports:

```sh
wpctl status
```

And the hardware gain itself, with `alsamixer` — not installed, so run it on
demand (F4 switches to capture devices, the arrow keys move the gain, Esc
quits):

```sh
nix run nixpkgs#alsa-utils -- alsamixer
```

If that slider is already at the top, that is the ceiling.

## Bluetooth

On hermes (`modules/system/bluetooth.nix` + the host's override), on zeus only
if you add `bluetooth` to its host list.

- **Pair a device** from noctalia's control center — the Bluetooth section
  lists what's nearby.
- On hermes, **Bluetooth starts switched off** at boot to save battery
  (`powerOnBoot = false` in `modules/hosts/hermes/hermes.nix`). The service
  still runs, so the toggle in the control center turns it on for the session;
  after a reboot it is off again. To change that, delete that `mkForce` line
  in the host file.
- From a terminal, if the control center won't cooperate (`bluetoothctl` comes
  with the Bluetooth module, so it only exists on a machine that has it):
  ```sh
  bluetoothctl
  ```
  Then `power on`, `scan on`, `pair <MAC>`, `trust <MAC>`, `connect <MAC>`,
  `exit`.
- Is the service alive?
  ```sh
  systemctl status bluetooth
  ```
- A headset connects but has no sound? Check it actually appeared as an
  output:
  ```sh
  wpctl status
  ```

## Monitors

niri detects monitors by itself, so `config.kdl` has no `output` block at all
right now.

```sh
niri msg outputs
```

That prints each monitor's name (like `DP-1`), its modes, the current mode and
its position. To pin something — a refresh rate niri picked wrong, a scale, or
the left-right arrangement — add a block to
`modules/programs/niri/config.kdl`:

```kdl
output "DP-1" {
    mode "2560x1440@165"
    scale 1
    position x=0 y=0
}
```

Then `nrs`; niri reloads immediately.

Moving windows between monitors: **Mod+Shift+Left/Right** to focus one,
**Mod+Ctrl+Shift+arrows** to send a column there. On zeus the mouse's side
buttons do the focusing too. See [niri.md](niri.md#monitors).

**Mod+Shift+Alt+L** switches the monitors off (any key wakes them).

## The graphics card

The driver comes with the kernel and Mesa; there is nothing to install.
`hardware.enableRedistributableFirmware` is on (`modules/system/boot.nix`), so
the firmware blobs AMD and Intel cards need are there.

Is it working?

```sh
vulkaninfo --summary
```

It should name your card. **`llvmpipe` means the driver did not load** and the
CPU is drawing everything — correct picture, terrible speed. If you see that:

```sh
journalctl -k -b | grep -i "amdgpu\|nvidia\|i915\|drm"
```

What card is it, physically?

```sh
lspci | grep -i vga
```

A borrowed package from `nixpkgs-stable` can also fail to load the driver —
that is a specific, documented trap, in
[updating.md](updating.md#the-trap-learned-the-hard-way).

## Keyboard and mouse

Two separate settings, because there are two separate systems:

| where | file | affects |
|---|---|---|
| the desktop | `modules/programs/niri/config.kdl`, `input` block | everything graphical |
| the text console | `modules/system/locale.nix`, `console.keyMap` | Ctrl+Alt+F2, the boot messages, the login screen |

Changing one does not change the other. Both are currently `de`.

In niri's `input` block:

```kdl
input {
    keyboard {
        xkb { layout "de" }
        numlock
        repeat-delay 400
        repeat-rate 30
    }
    touchpad {
        natural-scroll
        accel-profile "flat"
    }
    mouse {
        accel-profile "flat"
        scroll-factor 1.0
    }
    warp-mouse-to-focus
    focus-follows-mouse max-scroll-amount="10%"
}
```

| setting | does |
|---|---|
| `repeat-delay` / `repeat-rate` | how long before a held key repeats, and how fast. Deliberately fast here |
| `accel-profile "flat"` | no mouse acceleration — the pointer moves exactly as far as you moved the mouse. What you want for games |
| `natural-scroll` | touchpad scrolls like a phone |
| `warp-mouse-to-focus` | the pointer jumps to a window when you focus it with the keyboard |
| `focus-follows-mouse` | hovering a window focuses it. `max-scroll-amount` stops it dragging the whole strip around |

A touchpad tap-to-click line is in the file, commented out.

## RGB lighting (zeus)

`modules/programs/openrgb/openrgb.nix`. All the lighting — motherboard, case
fans, graphics card, RAM — is set to a dim cyan at every boot.

**Deliberately not the palette.** The lights have their own colour, in that
file, in `RRGGBB` hex without the `#`:

```nix
devices = {
  mystic = { mode = "direct"; colour = "002828"; };   # motherboard + case fans
  radeon = { mode = "static"; colour = "001414"; };   # graphics card
  fury   = { mode = "direct"; colour = "000c0c"; };   # RAM
};
```

The three numbers are red, green and blue from `00` (off) to `ff` (full). So
the same cyan brighter is `003c3c`, dimmer is `000a0a`. Change a value, `nrs`,
and the service re-runs immediately — no reboot needed.

The device **name** is any part of what OpenRGB calls it, case-insensitively,
so `fury` covers all the RAM sticks at once.

### How it works

1. `openrgb.service` runs OpenRGB as a root server (root is needed to reach
   RAM and motherboard LEDs over i2c). It scans for devices **once**, when it
   starts — so it is made to wait for the Mystic Light USB controller, the
   last device to appear (~10 s after power-on). Without that wait it used to
   find only the RAM.
2. `openrgb-colour.service` waits until the server lists every device, sizes
   the fan headers, then gives each one its mode and colour. It runs again on
   every rebuild.
3. The **OpenRGB GUI** (`openrgb` in the launcher) also connects to the
   server, so you can still play with colours live. The boot colour comes back
   next boot.

### The fan headers

OpenRGB cannot tell how many LEDs hang off a motherboard fan header, so it
starts every one at 0 LEDs — and then the fans get no colour at all. The
config sizes zones 0–3 of the motherboard at 120 LEDs each. Too many is
harmless; too few leaves the end of a chain dark.

### When the lights are wrong

```sh
systemctl status openrgb-colour
```

That shows the error. Usually a device name doesn't match, or a device doesn't
support that mode. To see the real names and modes:

```sh
openrgb --client --list-devices
```

A device missing from that list means the server didn't see it when it
scanned:

```sh
sudo systemctl restart openrgb
```

## The Corsair mouse (zeus)

`modules/programs/corsair/corsair.nix`. The Scimitar RGB Elite's **12 side
buttons**, remapped to the characters a German keyboard hides behind AltGr.

The interesting part: this mouse plugs in as **two** input devices — a pointer,
and a whole keyboard for the side pad. The side pad simply *types keys*,
straight from the mouse's onboard profile. So **keyd** (a remapping daemon
that sits between the kernel and niri) can give them any meaning, with no
vendor protocol involved at all. It grabs only the keyboard half of the mouse,
so your real keyboard keeps typing `1 2 3`.

What they type now:

```nix
"1" = "G-7";          # {   AltGr+7
"2" = "G-8";          # [   AltGr+8
"3" = "G-9";          # ]   AltGr+9
"4" = "G-0";          # }   AltGr+0
"5" = "G-minus";      # \   AltGr+ß
"6" = "G-rightbrace"; # ~   AltGr++
"7" = "apostrophe";   # ä
"8" = "semicolon";    # ö
"9" = "leftbrace";    # ü
"0" = "S-0";          # =   Shift+0
"minus" = "S-comma";  # ;   Shift+,
"equal" = "G-102nd";  # |   AltGr+<
```

**Both sides are names of physical keys**, because keyd works *below* the
keyboard layout. So the right-hand side is the German key that carries the
character you want, not the character itself: `G-` = AltGr, `S-` = Shift,
`minus` = the ß key, `rightbrace` = `+`, `leftbrace` = ü, `semicolon` = ö,
`apostrophe` = ä, `102nd` = the `< > |` key left of Y.

### If a button does the wrong thing

The left-hand side is the mouse's factory mapping (the pad types 1–9, 0, ß, ´
top-left to bottom-right). If a button was ever changed in iCUE on a Windows
machine, it sends something else. Read off what it actually sends:

```sh
sudo nix run nixpkgs#evtest
```

Pick the *"… SCIMITAR RGB ELITE Gaming Mouse Keyboard"* device, press the
button, and note the key in the `(KEY_...)` part — `KEY_4` is `"4"`,
`KEY_MINUS` is `"minus"`. Put that name on the left.

keyd's own key names:

```sh
keyd list-keys
```

### If nothing happens at all

```sh
systemctl status keyd
```
```sh
sudo keyd monitor
```
```sh
keyd list-devices
```

The daemon logs the device it matched. If the mouse isn't listed, the USB id
in the config is wrong.

### What cannot be done

The two buttons under the wheel can't be remapped. They emit **nothing** on
either input node — measured, not assumed. They step the DPI stage inside the
mouse's firmware and the host is never told, which is why the cursor speed and
the LED colour change but no key arrives. Nothing at the input layer can see
them, so keyd and udev are both out. The mouse's RGB and DPI steps can't be
configured either: this revision reports a USB id no open Corsair tool knows,
and speaks Corsair's newer protocol that none of them drive.

To remove it all when the mouse is gone: delete
`modules/programs/corsair/` and the `corsair` line in
`modules/hosts/zeus/zeus.nix`. Nothing else refers to it.

## The be quiet! fan controller (zeus)

This is why **Brave** is installed next to Firefox. The controller is
configured at `iocenter.bequiet.com`, which talks to the device over **WebHID**
— an API Firefox does not have and Mozilla will not add. There is no setting
that fixes it; it needs a Chromium-based browser.

`modules/programs/brave/brave.nix` does both halves:

1. A policy hands the device to that one site without a "choose a device"
   dialog every time.
2. A **udev rule** gives the logged-in user access to the device node. Without
   it the picker comes up empty, because `/dev/hidraw*` belongs to root.

The udev rule has one subtlety worth knowing if it ever breaks: it has to be
read *before* systemd's own rule that turns the tag into an access
permission, so it ships as its own file numbered `60-`. Writing it through
`services.udev.extraRules` (which lands in `99-local.rules`) silently does
nothing.

This is also the rule be quiet!'s own installer tries to write — the
`wget … | sudo bash` the site tells you to run. That script writes into
`/etc/udev/rules.d`, which on NixOS is a read-only link into the store, so it
fails even under sudo. Nothing to run by hand; the rebuild puts the file there.

Check which policies actually arrived: open `brave://policy` in Brave.

## The autoclicker

`modules/programs/ydotool/ydotool.nix`. **"Autoclicker"** in the launcher
(Mod+Space): a small window with clicks per second, which button, how many
clicks and a start delay.

It clicks in **every** window — Wayland apps, X11 apps and games — because it
isn't faking clicks at the application level. It creates a *real* fake mouse
in the kernel, which niri reads like any other USB mouse.

How the pieces fit:

1. `ydotoold` (a system service) creates the fake mouse and keyboard. Only
   members of the `ydotool` group may use it.
2. `ydotool click …` tells `ydotoold` what to click.
3. The Autoclicker window is the GTK front end on top.
4. **A start/stop key** can be set in the window (F8, a mouse side button, …).
   It works in every window while the Autoclicker is open, because the app
   reads the keyboards and mice directly from `/dev/input` — which needs the
   `input` group.

Both groups are on your user already (`modules/users/slider.nix`). Its own
settings live in `~/.config/autoclicker/settings.json`, written by the window.

- Nothing clicks until you press **Start**. Stop, or closing the window, ends
  it.
- The window floats instead of taking a column — a window rule in
  `config.kdl`.
- **Some online games treat fast autoclicking as cheating.** Your call.
- Not working?
  ```sh
  systemctl status ydotoold
  ```
  ```sh
  groups
  ```
  (`ydotool` and `input` should both be listed. A freshly added group needs a
  logout.)

## The data drive (zeus)

A 1.9 TB ext4 drive mounted at **`/mnt/data`**, declared in
`modules/hosts/zeus/zeus.nix`:

```nix
fileSystems."/mnt/data" = {
  device = "/dev/disk/by-uuid/0574158e-…";
  fsType = "ext4";
  options = ["nofail" "x-gvfs-show" "x-gvfs-name=Data"];
};
```

| option | does |
|---|---|
| `nofail` | **boot continues even if the drive is missing or broken.** Without this, a dead drive means a machine that won't boot |
| `x-gvfs-show` | list it in Thunar's sidebar under Devices — drives mounted outside `/media` are hidden otherwise |
| `x-gvfs-name=Data` | what Thunar calls it |

The last two are only read by Thunar and GVfs, not by `mount`. **GVfs doesn't
notice when a rebuild changes them**, so after editing those, either log out
and in or:

```sh
systemctl --user restart gvfs-udisks2-volume-monitor
```

Why this matters: **a reinstall erases the system drive, not this one.** Which
makes `/mnt/data` the right place for a Steam library, VM images you want to
keep, and a copy of your SSH key before a reinstall — see
[install.md](install.md#reinstalling-a-configured-host-example-zeus).

Adding another drive: copy that block into the host file with the new drive's
UUID. Find it with:

```sh
lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT
```

## USB sticks and other drives

Plug one in and it mounts by itself — `thunar-volman` does that
(`modules/programs/thunar/thunar.nix`), and `gvfs` gives you the trash and
network places. It appears in Thunar's sidebar.

If mounting asks for a password, that is polkit, and the GNOME agent
(`modules/system/polkit.nix`) is what shows the dialog. If no dialog appears
at all and the mount just fails silently, the agent isn't running:

```sh
systemctl --user status polkit-gnome-authentication-agent-1
```

From a terminal:

```sh
lsblk
```
```sh
udisksctl mount -b /dev/sdb1
```

## The keyboard-dead-after-reboot quirk (zeus)

Covered in full in
[troubleshoot.md](troubleshoot.md#the-keyboard-is-dead-after-a-reboot). The
short version: zeus' USB hub keeps power on its ports through a warm reboot,
so the keyboard's chip never restarts. `modules/system/reboot.nix` cuts the
power on the way down and power-cycles any port that came up dead. It is
handled; the commands to verify it are on that page.

## Battery and power (hermes)

- **The battery readout** in the bar comes from `upower`, enabled by
  noctalia's module.
- **Power profiles** (performance / balanced / power saver) come from
  `power-profiles-daemon`, and noctalia's control center has the toggle.
- **Screen brightness** is `brightnessctl`, driven by the brightness keys with
  an on-screen display.
- **Bluetooth is off at boot** to save battery, see
  [Bluetooth](#bluetooth).
- From a terminal:
  ```sh
  upower -i /org/freedesktop/UPower/devices/battery_BAT0
  ```
  ```sh
  powerprofilesctl
  ```
  ```sh
  brightnessctl set 50%
  ```

## Finding out what hardware you have

| command | shows |
|---|---|
| `fastfetch` | the summary: CPU, GPU, RAM, kernel, uptime |
| `lspci` | everything on the PCI bus. Pipe it through `grep -i vga` for the graphics card |
| `lsusb` | everything on USB, with vendor and product ids |
| `lsblk -o NAME,SIZE,FSTYPE,UUID,MOUNTPOINT` | disks, partitions, filesystems and UUIDs |
| `free -h` | RAM and zram |
| `btop` | live load, temperatures, fan speeds where available |
| `journalctl -k -b` | the kernel's own account of what it found at boot |
| `ls /sys/class/power_supply/` | batteries and power adapters |
| `sensors` | temperatures, if `lm_sensors` is installed |

`lsusb`'s ids are what a udev rule or a keyd config needs — the
`1b1c:1be3`-style pair. That is how the Corsair mouse and the be quiet!
controller are identified in this repo.
