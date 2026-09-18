{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # btop (system monitor), wrapped. The "TTY" theme draws with the 16 terminal
  # colours, so it follows the palette through alacritty automatically.
  # Settings changed inside btop are not saved (the config is in the store).
  flake.wrappers.btop = {wlib, ...}: {
    imports = [wlib.wrapperModules.btop];
    settings = {
      color_theme = "TTY";
      theme_background = false;
      update_ms = 1000;
      proc_filter_kernel = true;
    };
  };

  flake.nixosModules.btop = {
    imports = [wrappers.btop.install];
    wrappers.btop.enable = true;
  };
}
