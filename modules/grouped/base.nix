{self, ...}: {
  # Everything every machine needs, desktop or not.
  flake.nixosModules.base = {
    imports = with self.nixosModules; [
      # system/
      boot          # boot, swap, kernel
      locale        # time zone, language, keyboard layout
      network       # network i guess
      nix           # nixos settings
      nix-ld        # libraries
      reboot        # usb reset on reboot
      stable        # escape hatch for broken packages

      # programs/
      bat           # formatted cat command
      btop          # tui system info
      cli           # command-line tools
      fastfetch     # host information in the terminal
      fresh         # tui text editor
      git           # sync repo
      nix-tools     # nixd, nil, alejandra for the editors
      zsh           # shell
    ];
  };
}
