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
      fresh
      nix-tools # nixd, nil, alejandra for the editors
      claude-code
      thunar
      mpv
      imv
      shortwave
      rnote
      libreoffice
      rustdesk
      mediawriter
      ydotool # autoclicker ("Autoclicker" in the launcher)
    ];
  };
}
