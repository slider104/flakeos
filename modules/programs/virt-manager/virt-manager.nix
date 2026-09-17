{
  # virt-manager: the window where you create, start and watch the machines
  # that system/libvirt runs. The same program the Debian/Fedora guides use.
  #
  # Its settings live in dconf, like a GNOME app, so everything below is only a
  # *default* - change it in the GUI and your change wins from then on. The
  # package itself is wrapped for one thing only: GDK_BACKEND, see below.
  flake.nixosModules.virt-manager = {
    lib,
    pkgs,
    ...
  }: {
    # Installs virt-manager and points it at this machine's libvirtd
    # (qemu:///system), so it connects without being asked.
    programs.virt-manager = {
      enable = true;

      # Started on XWayland instead of natively on Wayland. As a Wayland client
      # its SPICE window never learns that something else on this machine has
      # copied something, so the clipboard stops travelling to the guest as
      # soon as the guest copies anything. On XWayland it sees every change,
      # and niri-clipboard-bridge (programs/niri) carries the clipboard between
      # XWayland and niri. See README.md next to this file, "The clipboard".
      package = pkgs.symlinkJoin {
        name = "virt-manager-x11";
        paths = [pkgs.virt-manager];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/virt-manager --set GDK_BACKEND x11
        '';
      };
    };

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
            # Needs the guest agent inside the guest, see README.md next to this file.
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
