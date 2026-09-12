{inputs, ...}: {
  # The disk layout shared by every host:
  #
  #   ESP  1G     vfat  /boot
  #   root rest   ext4  /
  #
  # No swap partition: RAM is backed by zram (system/boot.nix).
  # Only used by the `disko` command during installation (see README) and by
  # the running system to know its fileSystems. It never touches other disks.
  flake.lib.mkDisko = {device}: {
    imports = [inputs.disko.nixosModules.disko];

    disko.devices.disk.main = {
      inherit device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["umask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["noatime"];
            };
          };
        };
      };
    };
  };
}
