{self, ...}: {
  # BLUEPRINT: which disk the installer formats (layout: modules/setup/disko.nix,
  # ESP + ext4 root). Real one in this repo: hosts/zeus/disko.nix.
  #
  # On the machine, list the disks by their permanent names:
  #   ls -l /dev/disk/by-id/ | grep -v part
  # and pick the system disk (nvme-<model>_<serial>). Never use /dev/nvme0n1
  # style names: they can swap between boots, and the wrong disk gets erased.
  #
  # While this says CHANGE-ME, disko refuses to run: the path doesn't exist.
  flake.nixosModules.example-disko = self.lib.mkDisko {
    device = "/dev/disk/by-id/CHANGE-ME";
  };
}
