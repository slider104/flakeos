{
  flake.nixosModules.boot = {pkgs, ...}: {
    # UEFI + systemd-boot. Every rebuild adds a boot entry, and those entries
    # are your rollback: pick an older generation in the boot menu.
    boot.loader.systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    boot.loader.efi.canTouchEfiVariables = true;
    # Short window to reach the generation menu for a rollback.
    boot.loader.timeout = 3;

    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.tmp.cleanOnBoot = true;

    # Graphical splash instead of the scrolling console log, on boot and
    # shutdown. "spinner" draws the logo below on a black background.
    # Plymouth draws the logo at its native pixel size without scaling, so
    # the module's 48x48 default is a speck on a 1440p screen.
    boot.plymouth = {
      enable = true;
      theme = "spinner";
      logo = "${pkgs.nixos-icons}/share/icons/hicolor/512x512/apps/nix-snowflake.png";
    };

    # Plymouth only covers the console if the console stays quiet: "quiet"
    # plus a log level of 3 keeps errors on screen but drops the rest, and
    # the initrd stops narrating its own progress.
    boot.kernelParams = ["quiet" "udev.log_level=3"];
    boot.consoleLogLevel = 3;
    boot.initrd.verbose = false;

    # Compressed swap in RAM instead of a swap partition.
    zramSwap.enable = true;

    hardware.enableRedistributableFirmware = true;
  };
}
