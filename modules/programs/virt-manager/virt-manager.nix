{
  # virt-manager: the window where you create, start and watch the machines
  # that system/libvirt runs. The same program the Debian/Fedora guides use.
  #
  # Not wrapped: it stores its settings in dconf, like a GNOME app. Everything
  # below is only a *default* - change it in the GUI and your change wins from
  # then on.
  flake.nixosModules.virt-manager = {
    lib,
    pkgs,
    ...
  }: {
    # Installs virt-manager and points it at this machine's libvirtd
    # (qemu:///system), so it connects without being asked.
    programs.virt-manager.enable = true;

    # Opens only the screen of a machine, without the manager window.
    environment.systemPackages = [pkgs.virt-viewer];

    programs.dconf = {
      enable = true; # where virt-manager keeps its settings (system/theme also turns it on)
      profiles.user.databases = [
        {
          settings = {
            # What the "New virtual machine" wizard starts with.
            "org/virt-manager/virt-manager/new-vm" = {
              # The guest sees this machine's real CPU with all its features
              # instead of a generic model. This is the single biggest speed
              # setting. The price: such a machine expects a comparable CPU if
              # you ever copy it to another PC.
              cpu-default = "host-passthrough";

              # Boot guests like a modern PC (UEFI) instead of a 1990s BIOS.
              # Windows 11 requires it, Linux is happy with it.
              firmware = "uefi";

              # SPICE: the display protocol with shared clipboard, automatic
              # resolution and USB redirection.
              graphics-type = "spice";

              # Disk images that only take up what they really hold and can be
              # snapshotted (Manage snapshots in the machine's window).
              storage-format = "qcow2";
            };

            # The guest's resolution follows the window while you resize it.
            # Needs the guest agent inside the guest, see the README.
            "org/virt-manager/virt-manager/console".resize-guest = lib.gvariant.mkInt32 1;

            # Show the XML tab in a machine's details: every knob libvirt has,
            # including the ones with no button.
            "org/virt-manager/virt-manager".xmleditor-enabled = true;
          };
        }
      ];
    };
  };
}
