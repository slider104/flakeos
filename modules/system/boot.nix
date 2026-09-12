{
  flake.nixosModules.boot = {pkgs, ...}: {
    # UEFI + systemd-boot. Every rebuild adds a boot entry, and those entries
    # are your rollback: pick an older generation in the boot menu.
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.tmp.cleanOnBoot = true;

    # Compressed swap in RAM instead of a swap partition.
    zramSwap.enable = true;

    hardware.enableRedistributableFirmware = true;
  };
}
