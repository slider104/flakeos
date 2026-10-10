{
  flake.nixosModules.boot = {pkgs, ...}: {
    # UEFI + systemd-boot. Every rebuild adds a boot entry, and those entries
    # are your rollback: pick an older generation in the boot menu.
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 30;
    };
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.tmp.cleanOnBoot = true;

    # Compressed swap in RAM instead of a swap partition. Half the RAM at
    # most, and only the part that is actually swapped is used.
    zramSwap.enable = true;

    # The kernel's swap defaults assume swap lives on a disk, where swapping
    # a page out is expensive. Ours is compressed RAM: writing a page costs a
    # fraction of a millisecond and no seek at all. So:
    #
    #   swappiness 180   swap idle pages out readily instead of first
    #                    throwing away the file cache (the scale ends at 200;
    #                    values above 100 exist since kernel 5.8 for exactly
    #                    this case - swap that is as fast as RAM).
    #   page-cluster 0   read swapped pages back one at a time. Fetching
    #                    eight neighbours at once only pays off on a
    #                    spinning disk.
    boot.kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.page-cluster" = 0;
    };

    hardware.enableRedistributableFirmware = true;
  };
}
