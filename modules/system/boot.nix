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
      # wallpapers/nix00.png is a 1183x1024 RGBA snowflake; scaled down to
      # 512 tall it stays sharper than the 512 icon from nixos-icons. Nix
      # only sees git-tracked files, so keep this one committed.
      logo = pkgs.runCommand "nixos-logo-512.png" {nativeBuildInputs = [pkgs.imagemagick];} ''
        magick ${../../wallpapers/nix00.png} -resize x512 $out
      '';
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
