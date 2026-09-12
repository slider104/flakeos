{config, ...}: let
  theme = config.theme;
in {
  # OpenRGB: all RGB lighting in the palette's accent colour, set at every boot.
  #
  # How it works:
  #   1. `openrgb.service` (from NixOS) runs OpenRGB as a root server. Root is
  #      needed to reach RAM/motherboard LEDs over i2c/SMBus.
  #   2. `openrgb-colour.service` connects to that server once it's up and sets
  #      every device to static + accent colour.
  #   3. The OpenRGB GUI (`openrgb`) also connects to the server, so you can
  #      still play with it; the boot colour comes back next boot.
  #
  # If a device stays dark: run `openrgb --client --list-devices` to see its
  # modes. Some only have "direct" instead of "static".
  flake.nixosModules.openrgb = {
    config,
    pkgs,
    lib,
    ...
  }: let
    openrgb = config.services.hardware.openrgb.package;
    port = toString config.services.hardware.openrgb.server.port;
    colour = lib.removePrefix "#" theme.accent;
  in {
    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd"; # loads the AMD SMBus driver (i2c-piix4)
    };

    systemd.services.openrgb-colour = {
      description = "Set all RGB devices to the flakeos accent colour";
      after = ["openrgb.service"];
      requires = ["openrgb.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        # The server scans for devices after it starts; give it time to finish.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
        ExecStart = "${lib.getExe openrgb} --client 127.0.0.1:${port} --mode static --color ${colour}";
      };
    };
  };
}
