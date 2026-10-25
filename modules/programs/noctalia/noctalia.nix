{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
in {
  # noctalia: bar, launcher, notifications, OSD, lock screen, wallpaper.
  # Started by niri (`spawn-at-startup` in niri/config.kdl).
  #
  # This is noctalia 5, a rewrite of the 4.x shell this config used until
  # 2026-10-25 (C++ instead of QuickShell/QML, one TOML file instead of
  # settings.json + colors.json, `noctalia msg ...` instead of
  # `noctalia-shell ipc call ...`). nix-wrapper-modules has no module for it,
  # so this is a hand-written wrapper: package + the environment variable that
  # points at our config (see blueprints/programs/wrapped-custom/).
  #
  # Declarative: config.toml (next to this file) plus fonts and colours from
  # the palette, built into one config folder in the store. The settings GUI
  # (Mod+Comma) stays fully usable: noctalia writes GUI changes to
  # ~/.local/state/noctalia/settings.toml, which it reads *after* our file, so
  # they win until you remove them. To keep something:
  #   1. change it in the GUI
  #   2. `noctalia-changes` shows what you changed
  #   3. `noctalia-changes --save` writes it into config.toml; rebuild
  #   4. `noctalia-changes --clear` drops the GUI copy
  # (see noctalia-changes.py next to this file, and the README)
  #
  # Wallpapers: the images in flakeos/wallpapers/ (repo root) are installed to
  # /etc/wallpapers. Mod+W picks one; noctalia remembers it in its state file,
  # so it stays across logins. To add one, drop the file in, `git add` it,
  # rebuild.
  #
  # Three things the 4.x module needed and this one doesn't:
  #   - a script that wrote ~/.cache/noctalia/shell-state.json before every
  #     start, to skip the telemetry question and the changelog. 5 has no
  #     changelog popup, and `setup_wizard_enabled = false` in config.toml
  #     covers the first-run wizard.
  #   - a QML patch that recoloured the system monitor's numbers. There is no
  #     QML left to patch; widget colours are plain settings now.
  #   - a snapshot hook for `noctalia-changes`. GUI changes land in their own
  #     file, so there is nothing to compare against any more.
  flake.wrappers.noctalia = {
    wlib,
    lib,
    pkgs,
    config,
    ...
  }: let
    toml = pkgs.formats.toml {};
    json = pkgs.formats.json {};

    # The launcher button's icon, the NixOS logo (noctalia 4 found it through
    # the icon theme; 5 wants a path).
    nixLogo = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

    # Noctalia's 16 colour roles, filled from the palette, in the format it
    # calls a palette file. `dark` is used for both modes; we only run dark.
    # The terminal block is only read by noctalia's theme templates (off in
    # config.toml), but it belongs to a complete palette, so it is here.
    palette = json.generate "flakeos.json" {
      dark = {
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
        terminal = {
          background = theme.bg;
          foreground = theme.text;
          cursor = theme.text;
          cursorText = theme.bg;
          selectionBg = theme.accent;
          selectionFg = theme.onAccent;
          inherit (theme) normal bright;
        };
      };
    };

    # The folder noctalia reads: config.toml plus the palette next to it.
    # NOCTALIA_CONFIG_HOME works like XDG_CONFIG_HOME, so it points at the
    # folder *above* the "noctalia" one.
    #
    # `config validate` checks the generated file the way the running shell
    # reads it. An unknown or misspelled setting is a warning (noctalia
    # ignores it and says so), a broken value is an error and fails the
    # rebuild here instead of leaving you with a bar that won't start.
    configHome = pkgs.runCommand "noctalia-config" {} ''
      install -Dm444 ${toml.generate "config.toml" config.settings} \
        $out/noctalia/config.toml
      install -Dm444 ${palette} $out/noctalia/palettes/flakeos.json
      ${lib.getExe config.package} config validate $out/noctalia
    '';
  in {
    imports = [wlib.modules.default];

    # Our own option, so a host can change single settings - see
    # hosts/hermes/hermes.nix, which replaces the bar's right-hand widgets.
    options.settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Contents of noctalia's config.toml.";
    };

    config = {
      package = pkgs.noctalia;
      env.NOCTALIA_CONFIG_HOME = "${configHome}";

      settings = lib.mkMerge [
        (lib.importTOML ./config.toml)

        # From the palette, so there is one place for fonts and colours.
        {
          shell.font_family = theme.font.sans;
          widget.launcher.custom_image = nixLogo;
          widget.cpu.font_family = theme.font.mono;
          widget."cpu-temp".font_family = theme.font.mono;
          widget.ram.font_family = theme.font.mono;
        }
      ];
    };
  };

  flake.nixosModules.noctalia = {pkgs, ...}: let
    # `noctalia-changes [--save|--clear]`: what you changed in the settings
    # GUI. The script explains itself; tomlkit is what lets --save write into
    # config.toml without throwing its comments away.
    noctaliaChanges = pkgs.writers.writePython3Bin "noctalia-changes" {
      libraries = [pkgs.python3Packages.tomlkit];
      flakeIgnore = ["E501"]; # long lines in the help text
    } (builtins.readFile ./noctalia-changes.py);
  in {
    imports = [wrappers.noctalia.install];
    wrappers.noctalia.enable = true;

    # A fixed path (not a /nix/store path that changes with every new image),
    # so the remembered wallpaper stays valid across rebuilds.
    # ../../../wallpapers = flakeos/wallpapers. A relative path copies just
    # that folder into the store (not the whole repo).
    environment.etc."wallpapers".source = ../../../wallpapers;

    # Things noctalia's widgets talk to.
    services.upower.enable = true; # battery
    services.power-profiles-daemon.enable = true; # power profile toggle
    environment.systemPackages = [
      pkgs.brightnessctl # brightness OSD / keys
      noctaliaChanges
    ];

    # A fixed path to tomlkit, so Zed's Python checker (basedpyright) finds
    # the import while you edit noctalia-changes.py. Without it, Zed marks
    # `import tomlkit` as an error (the script itself works either way: the
    # package above brings its own copy). pyrightconfig.json in the repo root
    # points here. Same idea as /etc/autoclicker/python in programs/ydotool/,
    # but tomlkit is pure Python with no dependencies, so the library folder
    # itself is enough.
    environment.etc."noctalia-changes/python-libs".source = "${pkgs.python3Packages.tomlkit}/${pkgs.python3.sitePackages}";
  };
}
