{
  # Small command-line tools without any config, so nothing to wrap.
  flake.nixosModules.cli = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      curl
      wget
      unzip
      p7zip
      pciutils # lspci
      usbutils # lsusb
    ];
  };
}
