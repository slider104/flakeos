{
  # KVM: this machine's own hypervisor - the thing that runs another operating
  # system in a window at nearly the speed of the real hardware.
  #
  # Three pieces, all switched on here:
  #   KVM       the kernel part (kvm-amd / kvm-intel). It hands the guest real
  #             CPU cores instead of imitating them - that is why a VM can feel
  #             like a normal PC.
  #   QEMU      builds the machine around those cores: disk, network, screen.
  #   libvirtd  the service that stores the machine definitions and runs them.
  #
  # The window you click in is a separate module: programs/virt-manager.
  flake.nixosModules.libvirt = {
    config,
    pkgs,
    ...
  }: {
    virtualisation.libvirtd = {
      enable = true;

      # What happens to guests when the host boots or shuts down.
      # "ignore": only machines you marked "autostart" come up by themselves.
      # "shutdown": guests are asked to shut down properly (like pressing the
      # power button) instead of the default "suspend", which writes the whole
      # guest memory to disk on every host reboot - slow, and easy to break.
      onBoot = "ignore";
      onShutdown = "shutdown";

      qemu = {
        # Only this machine's own architecture. The full `qemu` can also
        # emulate foreign CPUs (aarch64 and friends) - much bigger, and that
        # kind of emulation is slow anyway, so it is not what we want.
        package = pkgs.qemu_kvm;

        # An emulated TPM 2.0 chip. Windows 11 refuses to install without one.
        swtpm.enable = true;

        # Shared folders between host and guest
        # (virt-manager: Add Hardware -> Filesystem).
        vhostUserPackages = [pkgs.virtiofsd];

        # Left alone: `runAsRoot`, which NixOS keeps at true. QEMU then runs as
        # root and can read ISOs and disk images anywhere, including your home
        # directory (which nobody else may enter). Set it to false and guests
        # run as the unprivileged user `qemu-libvirtd` - safer if you boot
        # machines you don't trust, but then every ISO and image must live
        # where that user can read it, e.g. /var/lib/libvirt/images.
      };
    };

    # UEFI firmware for guests needs no setting: libvirtd links the OVMF
    # images that come with QEMU into /run/libvirt/nix-ovmf by itself, and
    # virt-manager picks them up from there.

    # Lets you hand a USB device of this PC (stick, controller, phone) to a
    # running guest - the "USB device selection" in the machine's window.
    virtualisation.spiceUSBRedirection.enable = true;

    # libvirt brings a virtual network called "default": a NAT switch (virbr0)
    # with its own DHCP, so guests get an address and reach the internet
    # through the host, while nothing from outside reaches them. It ships
    # switched off - every guide starts with these two `virsh` commands.
    # This runs them for you, at every boot.
    systemd.services.libvirt-default-network = {
      description = "Start libvirt's default NAT network";
      wantedBy = ["multi-user.target"];
      requires = ["libvirtd.service"];
      after = ["libvirtd.service"];
      path = [config.virtualisation.libvirtd.package];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        virsh --connect qemu:///system net-autostart default
        if ! virsh --connect qemu:///system net-info default | grep -q "Active:.*yes"; then
          virsh --connect qemu:///system net-start default
        fi
      '';
    };
  };
}
