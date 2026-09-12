{self, ...}: {
  # The graphical desktop: niri + noctalia, dark theme, everyday apps.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      # system/
      login
      polkit
      xdg
      audio
      bluetooth
      fonts
      theme

      # programs/
      niri
      noctalia
      alacritty
      firefox
      zed
      thunar
      mpv
      imv
    ];
  };
}
