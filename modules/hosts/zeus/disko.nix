{self, ...}: {
  # zeus has two NVMe drives. disko ONLY formats the 1 TB system drive:
  #   KINGSTON SFYR2S1T0  953G   <- this one: /boot + /
  #   KINGSTON SFYR2S2T0  1.9T   <- data drive, never touched (mounted in zeus.nix)
  # by-id names contain the model + serial number, so unlike /dev/nvme0n1 they
  # can never swap between boots.
  flake.nixosModules.zeus-disko = self.lib.mkDisko {
    device = "/dev/disk/by-id/nvme-KINGSTON_SFYR2S1T0_50026B7283BBB0F9";
  };
}
