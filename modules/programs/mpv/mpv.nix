{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # mpv (video player), wrapped with the mpv.conf next to this file.
  flake.wrappers.mpv = {wlib, ...}: {
    imports = [wlib.wrapperModules.mpv];
    "mpv.conf".path = ./mpv.conf;
  };

  flake.nixosModules.mpv = {lib, ...}: {
    imports = [wrappers.mpv.install];
    wrappers.mpv.enable = true;

    # Double-clicking a video or audio file opens mpv.
    xdg.mime.defaultApplications = lib.genAttrs [
      "video/mp4"
      "video/x-matroska"
      "video/webm"
      "video/quicktime"
      "video/x-msvideo"
      "video/mpeg"
      "audio/mpeg"
      "audio/flac"
      "audio/ogg"
      "audio/x-wav"
      "audio/mp4"
    ] (_: "mpv.desktop");
  };
}
