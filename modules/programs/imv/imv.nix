{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
  noHash = builtins.substring 1 6; # "#0b0b0c" -> "0b0b0c" (imv wants bare hex)
in {
  # imv (image viewer), wrapped. Only a couple of settings, so they live here.
  flake.wrappers.imv = {wlib, ...}: {
    imports = [wlib.wrapperModules.imv];
    settings.options = {
      background = noHash theme.bg;
      overlay_font = "${theme.font.sans}:12";
      overlay_text_color = noHash theme.text;
      overlay_background_color = noHash theme.surface;
    };
  };

  flake.nixosModules.imv = {lib, ...}: {
    imports = [wrappers.imv.install];
    wrappers.imv.enable = true;

    # Double-clicking an image opens imv.
    xdg.mime.defaultApplications = lib.genAttrs [
      "image/png"
      "image/jpeg"
      "image/gif"
      "image/webp"
      "image/bmp"
      "image/tiff"
      "image/svg+xml"
    ] (_: "imv.desktop");
  };
}
