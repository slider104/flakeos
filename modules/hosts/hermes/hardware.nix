{
  # hermes hardware. STUB: replace the body with the real scan, run on hermes:
  #   nixos-generate-config --show-hardware-config --no-filesystems
  # (keep --no-filesystems: disko.nix owns the filesystems)
  flake.nixosModules.hermes-hardware = {
    lib,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  };
}
