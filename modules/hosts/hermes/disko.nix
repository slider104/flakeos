{self, ...}: {
  # TODO(hermes): set the real disk before installing. On hermes, run
  #   ls -l /dev/disk/by-id/ | grep -v part
  # and use the nvme-<model>_<serial> name. Until then, disko refuses to run
  # because this path doesn't exist, so it can't format anything by accident.
  flake.nixosModules.hermes-disko = self.lib.mkDisko {
    device = "/dev/disk/by-id/ata-SAMSUNG_MZ7LN256HAJQ-000L7_S3S7NX0M421713";
  };
}
