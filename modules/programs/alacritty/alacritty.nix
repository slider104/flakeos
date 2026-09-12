{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
in {
  # alacritty, wrapped: always starts with `--config-file <store path>`.
  # Settings = alacritty.toml (next to this file) + colours from the palette.
  flake.wrappers.alacritty = {
    wlib,
    lib,
    ...
  }: {
    imports = [wlib.wrapperModules.alacritty];

    settings =
      lib.recursiveUpdate (lib.importTOML ./alacritty.toml)
      {
        colors = {
          primary = {
            background = theme.bg;
            foreground = theme.text;
            dim_foreground = theme.muted;
            bright_foreground = theme.bright.white;
          };
          cursor = {
            text = theme.bg;
            cursor = theme.accent;
          };
          selection = {
            text = theme.onAccent;
            background = theme.accent;
          };
          search = {
            matches = {
              foreground = theme.bg;
              background = theme.muted;
            };
            focused_match = {
              foreground = theme.onAccent;
              background = theme.accent;
            };
          };
          footer_bar = {
            foreground = theme.text;
            background = theme.overlay;
          };
          normal = theme.normal;
          bright = theme.bright;
        };
      };
  };

  flake.nixosModules.alacritty = {
    imports = [wrappers.alacritty.install];
    wrappers.alacritty.enable = true;
  };
}
