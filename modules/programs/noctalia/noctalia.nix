{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
in {
  # noctalia-shell: bar, launcher, notifications, OSD, lock screen, wallpaper.
  # Started by niri (`spawn-at-startup` in niri/config.kdl).
  #
  # Declarative: settings.json (next to this file) + the palette are baked into
  # the store. The settings GUI (Mod+Comma) still works for trying things out,
  # but changes are gone after a restart. To keep something:
  #   1. change it in the GUI
  #   2. run `dump-noctalia-shell` - prints the current settings as Nix
  #   3. copy the keys you changed into settings.json, rebuild
  #
  # Only settings you set are here; everything else uses noctalia's defaults.
  #
  # Wallpapers: the images in flakeos/wallpapers/ (repo root) are installed to
  # /etc/wallpapers. Pick one with Mod+W; your choice is remembered in
  # ~/.cache/noctalia. To add one, drop the file in, `git add` it, rebuild.
  flake.wrappers.noctalia-shell = {
    wlib,
    lib,
    ...
  }: {
    imports = [wlib.wrapperModules.noctalia-shell];

    settings = lib.importJSON ./settings.json;

    # Noctalia's colour roles, filled from the palette.
    colors = {
      mPrimary = theme.accent;
      mOnPrimary = theme.onAccent;
      mSecondary = theme.bright.blue;
      mOnSecondary = theme.bg; # dark text on the light blue
      mTertiary = theme.bright.cyan;
      mOnTertiary = theme.bg; # dark text on the light cyan
      mError = theme.error;
      mOnError = theme.onAccent;
      mSurface = theme.bg;
      mOnSurface = theme.text;
      mSurfaceVariant = theme.surface;
      mOnSurfaceVariant = theme.muted;
      mOutline = theme.border;
      mShadow = "#000000";
      mHover = theme.overlay;
      mOnHover = theme.text;
    };
  };

  flake.nixosModules.noctalia = {pkgs, ...}: {
    imports = [wrappers.noctalia-shell.install];
    wrappers.noctalia-shell.enable = true;

    # A fixed path (not a /nix/store path that changes with every new image),
    # so the remembered wallpaper stays valid across rebuilds.
    # ../../../wallpapers = flakeos/wallpapers. A relative path copies just
    # that folder into the store (not the whole repo).
    environment.etc."wallpapers".source = ../../../wallpapers;

    # Things noctalia's widgets talk to.
    services.upower.enable = true; # battery
    services.power-profiles-daemon.enable = true; # power profile toggle
    environment.systemPackages = [pkgs.brightnessctl]; # brightness OSD / keys
  };
}
