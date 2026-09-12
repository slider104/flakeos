let
  # Mode + colour per device. The mode is from your old OpenRGB profile; the
  # colour is your dim cyan from it (001414), made brighter or dimmer per
  # device. Deliberately NOT the palette. Hex RRGGBB, without "#"; the three
  # numbers are red, green, blue from 00 (off) to ff (full), so the same cyan
  # brighter is e.g. 003c3c.
  # The name is any part of what `openrgb --client --list-devices` shows
  # (case doesn't matter), and every device that matches gets it, so "fury"
  # covers all RAM sticks.
  devices = {
    # MSI MYSTIC LIGHT (motherboard): the case fans, via its fan headers
    mystic = {
      mode = "direct";
      colour = "002828";
    };
    # Sapphire Radeon RX 9060 XT Nitro+ (graphics card)
    radeon = {
      mode = "static";
      colour = "001414";
    };
    # Kingston Fury DDR5 DRAM
    fury = {
      mode = "direct";
      colour = "000c0c";
    };
  };

  # The fan headers on the motherboard: zones 0-3 of "mystic" (JAF, JARGB 1,
  # JARGB 2, JARGB 3). OpenRGB can't tell how many LEDs hang off a header, so
  # it starts every one at 0 LEDs, and then the fans get no colour at all.
  # 120 per header covers several chained fans. Too many is harmless (colours
  # for LEDs that aren't there go nowhere); too few leaves the end dark.
  fanHeaders = {
    device = "mystic";
    zones = [0 1 2 3];
    leds = 120;
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
  #      above, sizes the fan headers, then gives each device its mode +
  #      colour. It also runs again on every rebuild.
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

    # --device mystic --mode direct --color 002828 --device radeon ...
    deviceArgs = lib.concatLists (lib.mapAttrsToList (name: d: [
        "--device"
        name
        "--mode"
        d.mode
        "--color"
        d.colour
      ])
      devices);

    # --device mystic --zone 0 --size 120 --color 002828 --zone 1 ...
    # (the CLI refuses a size without a colour, but only the last zone's
    # colour sticks, so the colours are set again afterwards)
    sizeArgs =
      ["--device" fanHeaders.device]
      ++ lib.concatMap (zone: [
        "--zone"
        (toString zone)
        "--size"
        (toString fanHeaders.leds)
        "--color"
        devices.${fanHeaders.device}.colour
      ])
      fanHeaders.zones;

    # The server only answers once its device scan is done (~10 s). Ask it
    # every 2 s until every name above is in its list (lines look like
    # "2: MSI MYSTIC LIGHT"), for at most 2 minutes. Then size the fan
    # headers and set the colours; if a device is still missing, that step
    # fails with "Cannot find device".
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
      ${client} ${lib.escapeShellArgs sizeArgs}
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
