{self, ...}: {
  # Everything every machine needs, desktop or not.
  flake.nixosModules.base = {
    imports = with self.nixosModules; [
      # system/
      boot
      nix
      network
      locale
      keyboard-reboot # USB keyboards that stay dark after a reboot

      # programs/
      zsh
      git
      btop
      fastfetch
      bat
      cli
    ];
  };
}
