{config, ...}: let
  theme = config.theme;
in {
  flake.nixosModules.fonts = {pkgs, ...}: {
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
    ];

    fonts.fontconfig.defaultFonts = {
      sansSerif = [theme.font.sans];
      serif = ["Noto Serif"];
      monospace = [theme.font.mono];
      emoji = ["Noto Color Emoji"];
    };
  };
}
