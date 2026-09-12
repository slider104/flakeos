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
  #   2. `openrgb-colour.service` connects to that server once it's up and
  #      gives every device above its mode + your colour.
  #   3. The OpenRGB GUI (`openrgb`) also connects to the server, so you can
  #      still play with it; the boot colour comes back next boot.
  #
  # If the lights don't change: `systemctl status openrgb-colour` shows the
  # error. Usually a device name above doesn't match, or a device doesn't
  # have that mode (`openrgb --client --list-devices` lists names + modes).
  flake.nixosModules.openrgb = {
    config,
    pkgs,
    lib,
    ...
  }: let
    openrgb = config.services.hardware.openrgb.package;
    port = toString config.services.hardware.openrgb.server.port;

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
  in {
    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd"; # loads the AMD SMBus driver (i2c-piix4)
    };

    systemd.services.openrgb-colour = {
      description = "Set all RGB devices to your colour";
      after = ["openrgb.service"];
      requires = ["openrgb.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        # The server scans for devices after it starts; give it time to finish.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
        ExecStart = lib.escapeShellArgs ([(lib.getExe openrgb) "--client" "127.0.0.1:${port}"] ++ deviceArgs);
      };
    };
  };
}
