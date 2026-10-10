{
  # Corsair Scimitar RGB Elite: the 12 side buttons.
  #
  # The mouse's own software (iCUE) is Windows-only, and this mouse is a
  # revision that no open Corsair tool knows: it reports USB 1b1c:1be3, while
  # ckb-next, OpenRGB and libratbag all only know the Scimitar RGB Elite as
  # 1b1c:1b8b. Its vendor interface also speaks Corsair's newer "Bragi"
  # protocol (HID usage page 0xFF42, 128-byte reports) instead of the older
  # 0xFFC2 that ckb-next drives the other Scimitars with. So there is nothing
  # to configure DPI steps, polling rate, onboard profiles or the RGB with.
  #
  # The buttons don't need any of that. The mouse plugs in as TWO input
  # devices, both 1b1c:1be3:
  #   - the pointer      ("... Gaming Mouse"),   movement + the 5 normal buttons
  #   - a whole keyboard ("... Gaming Mouse Keyboard"), the 12 side buttons
  # The side pad just types keys, straight from the mouse's onboard profile.
  # So keyd (a remapping daemon that sits between the kernel and niri) can
  # give them any meaning, with no vendor protocol involved.
  #
  # How it works:
  #   1. keyd grabs only the keyboard half of the mouse ("k:" below) and
  #      replaces the keys it names, for that device alone. Your real
  #      keyboard is untouched - it keeps typing 1, 2, 3, ...
  #   2. keyd re-emits them on its own virtual keyboard, which niri reads
  #      like any other, so this works in every window: Wayland, X11, games.
  #
  # The two buttons under the wheel CANNOT be remapped here. Measured by
  # reading both input nodes while pressing them: they emit nothing at all,
  # on either node (the side pad and the wheel do show up, so that was a real
  # result, not a broken test). They step the DPI stage inside the mouse's
  # firmware and the host is never told - that's why the cursor speed and the
  # LED colour change but no key arrives. Nothing at the input layer can see
  # them, so keyd and udev/hwdb are both out (hwdb needs ID_INPUT_KEY, and
  # the pointer node only has ID_INPUT_MOUSE). Giving them a real function
  # would mean rewriting the mouse's onboard profile over Bragi, which is a
  # block write to a device handle, not a simple property set.
  #
  # To remove it when the mouse is gone: delete this folder and the `corsair`
  # line in modules/hosts/zeus/zeus.nix. Nothing else refers to it.
  flake.nixosModules.corsair = {pkgs, ...}: {
    # What the 12 side buttons should type.
    #
    # On the LEFT is the key the button sends now, on the RIGHT the keystroke
    # keyd sends instead. Both are names of PHYSICAL keys (keyd works below
    # the keyboard layout), so the right-hand side is the German key that
    # carries the character you want, not the character itself:
    #   G- = AltGr, S- = Shift
    #   minus = the ß key, rightbrace = the + key, leftbrace = ü,
    #   semicolon = ö, apostrophe = ä, 102nd = the < > | key left of Y.
    # Checked against the de layout in xkeyboard-config (symbols/de plus
    # latin(type4)), which is what niri is set to in programs/niri/config.kdl.
    #
    # The left-hand side is the Scimitar's factory mapping: the pad types
    # 1-9, 0, ß, ´ top-left to bottom-right. If a button does the wrong
    # thing, it was changed in iCUE at some point - see "If a button is
    # wrong" at the bottom for how to read off what it really sends.
    services.keyd = {
      enable = true;
      keyboards.corsair = {
        # Only this mouse, and only its keyboard half. Without the "k:" keyd
        # would also grab the pointer half, which has nothing to remap.
        ids = ["k:1b1c:1be3"];

        settings.main = {
          "1" = "G-7"; # {   AltGr+7
          "2" = "G-8"; # [   AltGr+8
          "3" = "G-9"; # ]   AltGr+9
          "4" = "G-0"; # }   AltGr+0
          "5" = "G-minus"; # \   AltGr+ß
          "6" = "G-rightbrace"; # ~   AltGr++
          "7" = "apostrophe"; # ä
          "8" = "semicolon"; # ö
          "9" = "leftbrace"; # ü
          "0" = "S-0"; # =   Shift+0
          "minus" = "S-comma"; # ;   Shift+,
          "equal" = "G-102nd"; # |   AltGr+<
        };
      };
    };

    # If a button is wrong, read off what it actually sends:
    #   sudo nix run nixpkgs#evtest
    # pick the "Corsair CORSAIR SCIMITAR RGB ELITE Gaming Mouse Keyboard"
    # device, press the button, and note the key in the "(KEY_...)" part -
    # KEY_4 is "4", KEY_MINUS is "minus". Put that name on the left above.
    # keyd's own names: `keyd list-keys`.
    #
    # If nothing changes at all: `systemctl status keyd` and
    # `sudo keyd monitor`. The daemon logs the device it matched; if the
    # mouse isn't listed, the id above is wrong (`keyd list-devices`).

    # The RGB: every LED one dim cyan, from corsair-cyan.py next to this file.
    # The colour and the DPI are at the top of that script.
    #
    # It is a ONE-SHOT and must stay one. It sets software lighting mode, pins
    # the DPI, writes a single LED frame, and exits.
    #
    # Read this before changing it:
    #   An earlier version polled the DPI every 100ms and repainted, to give
    #   each of the five DPI stages its own colour. It worked, briefly. But in
    #   HARDWARE lighting mode the firmware repaints the same LEDs itself on
    #   every stage change, so there were two writers on one resource. The
    #   mouse started misbehaving (a stage that changed the lighting but not
    #   the DPI, bright default colours for a second or two) and then reset
    #   itself to factory settings. Writing lighting in hardware mode is not
    #   safe on this device even though the writes are accepted.
    #   SOFTWARE mode, which this uses, is safe because the mouse stops
    #   repainting - the same reason it disables DPI stage cycling.
    #
    # Trade-off, accepted deliberately: in software mode the two buttons under
    # the wheel do nothing at all. No DPI cycling, no colour changes. That was
    # wanted here; those buttons cannot be remapped either (see above).
    #
    # Nothing of this survives a power cycle: software mode and the LED frame
    # are both volatile. Hence it runs at boot AND on replug, via the udev
    # rule below. Re-running it by hand is harmless:
    #   sudo systemctl start corsair-cyan
    #
    # Facts worth keeping, all measured on this mouse (1b1c:1be3):
    #   - it speaks Corsair's Bragi protocol: 128-byte reports on the 0xFF42
    #     interface, packets [0x08][cmd][prop], GET 0x02 / SET 0x01.
    #   - DPI0/1/2_COLOR (0x2F-0x31) answer "not supported", so the per-stage
    #     colours are not reachable as properties; they live in the onboard
    #     profile, whose format is not known.
    #   - the LED frame is planar (all red, then green, then blue), written to
    #     handle 0 / resource 0x01, and the device takes the zone count from
    #     payload length / 3.
    #   - of zone indices 0-7 only four have LEDs: 0 logo, 1 wheel, 3 side
    #     buttons, 4 the stripe before the side pad.
    #   - the mouse sends no notification when anything changes on it.
    #
    # If the LEDs are not cyan: `systemctl status corsair-cyan` and
    # `journalctl -u corsair-cyan`. It prints the colour and DPI it set, or
    # the command that failed.
    systemd.services.corsair-cyan = {
      description = "Set the Corsair Scimitar LEDs to one colour";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 -I ${./corsair-cyan.py}";
        # The mouse is driven over /dev/hidraw*, which is root-only. This is
        # the vendor protocol, not an input device, so the `input` group does
        # not help.
      };
    };

    # Run it again whenever the mouse appears, so replugging restores the
    # colour without a reboot. The mouse has four hidraw nodes, so this fires
    # a few times; starting an already-running one-shot is a no-op.
    services.udev.extraRules = ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1b1c", ATTRS{idProduct}=="1be3", TAG+="systemd", ENV{SYSTEMD_WANTS}+="corsair-cyan.service"
    '';
  };
}
