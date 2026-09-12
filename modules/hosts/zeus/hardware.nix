{
  # zeus hardware, from `nixos-generate-config --show-hardware-config --no-filesystems`
  # (run on zeus, 2026-09-12). Filesystems come from disko.nix, not from here.
  # Ryzen CPU with iGPU + Radeon RX (RDNA4); both use the in-kernel amdgpu driver.
  flake.nixosModules.zeus-hardware = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];

    boot.initrd.availableKernelModules = ["nvme" "ahci" "xhci_pci_prom21" "xhci_pci" "thunderbolt" "usbhid"];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-amd"];
    boot.extraModulePackages = [];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
