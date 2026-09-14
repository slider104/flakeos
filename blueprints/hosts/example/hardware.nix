{
  # BLUEPRINT: the machine's hardware (kernel modules, CPU microcode, ...).
  # Replace this body with the real scan, run ON the machine:
  #
  #   nixos-generate-config --show-hardware-config --no-filesystems
  #
  # Copy everything between the outer `{ ... }` of its output into the block
  # below. Keep --no-filesystems: disko.nix owns the filesystems.
  # Real one in this repo: hosts/zeus/hardware.nix.
  flake.nixosModules.example-hardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
    boot.kernelModules = ["kvm-amd"]; # "kvm-intel" on Intel

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
