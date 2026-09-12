let
  # Your RGB colour, from your old OpenRGB profile: a dim cyan.
  # Deliberately NOT the palette. Hex RRGGBB, without "#".
  # (Brighter alternative: "7fc8ff", your old niri focus-ring blue.)
  colour = "001414";

  # Which mode each device uses, also from your old profile. The name is any
  # part of what `openrgb --client --list-devices` shows (case doesn't
  # matter), and every device that matches gets it, so "fury" covers all
  # RAM sticks.
  devices = {
    mystic = "direct"; # MSI MYSTIC LIGHT (motherboard)
    radeon = "static"; # Sapphire Radeon RX 9060 XT Nitro+ (graphics card)
    fury = "direct"; # Kingston Fury DDR5 DRAM
  };
in {
  # OpenRGB: sets all RGB lighting to your colour at every boot.
  #
  # How it works:
  #   1. `openrgb.service` (from NixOS) runs OpenRGB as a root server. Root is
  #      needed to reach RAM/motherboard LEDs over i2c/SMBus.
  #      The server looks for devices ONCE, when it starts. At boot it used to
  #      start before the graphics card's LED bus and the Mystic Light USB
  #      device existed, and only found the RAM. So it now waits for the
  #      Mystic Light, the last of them to show up (~10 s after power-on).
  #   2. `openrgb-colour.service` waits until the server lists every device
  #      above, then gives each its mode + your colour. It also runs again on
  #      every rebuild.
  #   3. The OpenRGB GUI (`openrgb`) also connects to the server, so you can
  #      still play with it; the boot colour comes back next boot.
  #
  # If the lights don't change: `systemctl status openrgb-colour` shows the
  # error. Usually a device name above doesn't match, or a device doesn't
  # have that mode (`openrgb --client --list-devices` lists names + modes).
  # If a device is missing from that list, `sudo systemctl restart openrgb`
  # makes the server look again.
  flake.nixosModules.openrgb = {
    config,
    pkgs,
    lib,
    ...
  }: let
    openrgb = config.services.hardware.openrgb.package;
    port = toString config.services.hardware.openrgb.server.port;
    client = "${lib.getExe openrgb} --client 127.0.0.1:${port}";

    # --device mystic --mode direct --color 001414 --device radeon ...
    deviceArgs = lib.concatLists (lib.mapAttrsToList (name: mode: [
        "--device"
        name
        "--mode"
        mode
        "--color"
        colour
      ])
      devices);

    # The server only answers once its device scan is done (~10 s). Ask it
    # every 2 s until every name above is in its list (lines look like
    # "2: MSI MYSTIC LIGHT"), for at most 2 minutes. Then set the colours; if
    # a device is still missing, that step fails with "Cannot find device".
    setColours = pkgs.writeShellScript "openrgb-set-colours" ''
      for _ in $(seq 60); do
        list=$(${client} --list-devices 2>/dev/null)
        missing=0
        for name in ${lib.escapeShellArgs (lib.attrNames devices)}; do
          echo "$list" | grep -qiE "^[0-9]+: .*$name" || missing=1
        done
        [ "$missing" = 0 ] && break
        sleep 2
      done
      exec ${client} ${lib.escapeShellArgs deviceArgs}
    '';
  in {
    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd"; # loads the AMD SMBus driver (i2c-piix4)
    };

    # Give the Mystic Light USB controller (vendor 0db0, product 0076) a
    # systemd name, dev-mysticlight.device, so the server can wait for it.
    # If it never shows up (unplugged, off in the BIOS), the server starts
    # anyway after systemd's 90 s device timeout.
    services.udev.extraRules = ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0db0", ATTRS{idProduct}=="0076", TAG+="systemd", ENV{SYSTEMD_ALIAS}+="/dev/mysticlight"
    '';
    systemd.services.openrgb = {
      wants = ["dev-mysticlight.device"];
      after = ["dev-mysticlight.device"];
    };

    systemd.services.openrgb-colour = {
      description = "Set all RGB devices to your colour";
      after = ["openrgb.service"];
      requires = ["openrgb.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = setColours;
      };
    };
  };
}
