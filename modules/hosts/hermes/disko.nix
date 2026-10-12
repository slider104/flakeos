{self, ...}: {
  # hermes has one SATA SSD, which disko formats into /boot + /:
  #   SAMSUNG MZ7LN256HAJQ-000L7  238G  <- this one
  # The DVD drive (HL-DT-ST DVDRAM GUE0N) is the only other device and is
  # never touched. Swap is zram, so there is no swap partition.
  # by-id names contain the model + serial number, so unlike /dev/sda they
  # can never swap between boots.
  flake.nixosModules.hermes-disko = self.lib.mkDisko {
    device = "/dev/disk/by-id/ata-SAMSUNG_MZ7LN256HAJQ-000L7_S3S7NX0M421713";
  };
}
