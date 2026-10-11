{self, ...}: {
  # The graphical desktop: niri + noctalia, dark theme, everyday apps.
  flake.nixosModules.desktop = {
    imports = with self.nixosModules; [
      # system/
      audio         # audio i guess
      dconf         # defaults for apps with configs in dconf
      fonts         # fonts i guess
      login         # autologin
      polkit        # sudo prompts for gui
      theme         # system wide theme
      xdg           # create home folders if missing

      # programs/
      alacritty     # terminal emulator
      brave         # internet browser
      claude-code   # ai agent
      firefox       # internet browser
      imv           # pictures
      mediawriter   # img writer
      mpv           # video
      niri          # window manager
      noctalia      # top bar
      rnote         # drawing board
      shortwave     # internet radio
      thunar        # file browser
      ydotool       # autoclicker ("Autoclicker" in the launcher)
      zed           # gui text editor
    ];
  };
}
