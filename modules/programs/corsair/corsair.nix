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
  };
}
