{self, ...}: {
  # The graphical desktop: niri + noctalia, dark theme, everyday apps.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      # system/
      login
      polkit
      xdg
      audio
      fonts
      theme

      # programs/
      niri
      noctalia
      alacritty
      firefox
      zed
      nix-tools # nixd, nil, alejandra for the editors
      claude-code
      thunar
      mpv
      imv
      shortwave
      rnote
      mediawriter
      ydotool # autoclicker ("Autoclicker" in the launcher)
    ];
  };
}
