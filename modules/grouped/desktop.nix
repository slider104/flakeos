{self, ...}: {
  # The graphical desktop: niri + noctalia, dark theme, everyday apps.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      # system/
      login
      polkit
      xdg
      audio
      dconf
      fonts
      theme

      # programs/
      niri
      noctalia
      alacritty
      firefox
      brave # 2nd browser, for WebHID sites (iocenter.bequiet.com)
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
