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
  # /etc/wallpapers. Every login starts with a random one (see prepareStart);
  # Mod+W picks another until the next login. To add one, drop the file in,
  # `git add` it, rebuild.
  flake.wrappers.noctalia-shell = {
    wlib,
    lib,
    pkgs,
    ...
  }: let
    # Runs before noctalia starts. It writes two files in ~/.cache/noctalia
    # (the only place noctalia keeps state; its config is in the store):
    #
    #   shell-state.json - noctalia shows a telemetry question and then the
    #     changelog when this file has no "last seen version". Filling it in
    #     on first start skips both. After that, showChangelogOnStartup =
    #     false in settings.json keeps the changelog away after updates.
    #     (The first-run setup wizard never shows: it only opens when
    #     settings.json is missing, and ours is in the store.)
    #
    #   wallpapers.json - noctalia's remembered wallpaper. Overwritten on
    #     every start with a random image from /etc/wallpapers.
    #
    # The same `noctalia-shell` command is used for keybinds
    # (`noctalia-shell ipc call ...`); those have arguments and are skipped.
    prepareStart = pkgs.writeShellScript "noctalia-prepare-start" ''
      [ $# -eq 0 ] || exit 0 # an ipc call, not a start

      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia"
      mkdir -p "$cache"

      if [ ! -e "$cache/shell-state.json" ]; then
        echo '{"changelogState": {"lastSeenVersion": "v${pkgs.noctalia-shell.version}"}}' \
          > "$cache/shell-state.json"
      fi

      shopt -s nullglob
      walls=(/etc/wallpapers/*)
      if [ ''${#walls[@]} -gt 0 ]; then
        pick=''${walls[RANDOM % ''${#walls[@]}]}
        echo "{\"defaultWallpaper\": \"$pick\"}" > "$cache/wallpapers.json"
      fi
    '';
  in {
    imports = [wlib.wrapperModules.noctalia-shell];

    runShell = [''${prepareStart} "$@"''];

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
