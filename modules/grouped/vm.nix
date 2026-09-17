{self, ...}: {
  # Virtual machines: run another operating system in a window, at nearly the
  # speed of the real hardware. How to set one up: the guide next to the window,
  # programs/virt-manager/README.md.
  flake.nixosModules.vm = {
    imports = with self.nixosModules; [
      libvirt # system/: KVM, QEMU, libvirtd - the machinery
      virt-manager # programs/: the window to create and run machines in
    ];
  };
}
