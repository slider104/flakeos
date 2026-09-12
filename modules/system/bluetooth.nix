{
  flake.nixosModules.bluetooth = {
    # Controllers, headsets. noctalia has the Bluetooth menu.
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
