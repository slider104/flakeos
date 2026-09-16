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
  #   2. `noctalia-changes` shows what you changed
  #   3. `noctalia-changes --save` adds that to settings.json; rebuild
  # (see noctaliaChanges below, and the README)
  #
  # Only settings you set are here; everything else uses noctalia's defaults.
  #
  # Wallpapers: the images in flakeos/wallpapers/ (repo root) are installed to
  # /etc/wallpapers. Mod+W picks one; it stays across logins. A random one on
  # every login is possible too (commented out in prepareStart). To add one,
  # drop the file in, `git add` it, rebuild.
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
    #   wallpapers.json - noctalia's remembered wallpaper. Can be overwritten
    #     on every start with a random image from /etc/wallpapers (commented
    #     out below).
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

      # Random wallpaper on every login.
      # Uncomment to turn it back on.
      # shopt -s nullglob
      # walls=(/etc/wallpapers/*)
      # if [ ''${#walls[@]} -gt 0 ]; then
      #   pick=''${walls[RANDOM % ''${#walls[@]}]}
      #   echo "{\"defaultWallpaper\": \"$pick\"}" > "$cache/wallpapers.json"
      # fi
    '';
  in {
    imports = [wlib.wrapperModules.noctalia-shell];

    runShell = [''${prepareStart} "$@"''];

    # System monitor panel (click the bar's system monitor): the numbers above
    # the graphs (CPU %, temperature, memory, network speed) are drawn in the
    # accent blues, hard to read on the dark card. No setting for it, so patch
    # them to the normal text colour. Icons and graph lines keep their colours.
    # --replace-fail: if an update changes that file, the build stops here
    # instead of silently dropping the fix.
    package = pkgs.noctalia-shell.overrideAttrs (old: {
      postPatch =
        (old.postPatch or "")
        + ''
          substituteInPlace Modules/Panels/SystemStats/SystemStatsPanel.qml \
            --replace-fail \
              $'color: Color.mPrimary\n              font.family: Settings.data.ui.fontFixed' \
              $'color: Color.mOnSurface\n              font.family: Settings.data.ui.fontFixed' \
            --replace-fail \
              $'color: Color.mSecondary\n              font.family: Settings.data.ui.fontFixed' \
              $'color: Color.mOnSurface\n              font.family: Settings.data.ui.fontFixed'
        '';
    });

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

  flake.nixosModules.noctalia = {pkgs, ...}: let
    # `noctalia-changes [--save]`: what you changed in the settings GUI.
    #
    # When noctalia starts, its startup hook (settings.json → "hooks") runs
    # `noctalia-changes --snapshot`, which saves noctalia's settings as they
    # are then. Later, `noctalia-changes` compares the live settings with
    # that snapshot and prints only what differs, as JSON in the shape of
    # settings.json. (Comparing with settings.json itself doesn't work:
    # noctalia fills in lots of defaults, e.g. every option of every bar
    # widget, which would all show up as "changed".)
    #
    # --save merges the changes into ~/flakeos/.../settings.json and takes a
    # new snapshot, so the next run only shows newer changes.
    noctaliaChanges = pkgs.writeShellApplication {
      name = "noctalia-changes";
      runtimeInputs = [pkgs.jq]; # noctalia-shell itself comes from PATH
      text = ''
        snapshot="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/settings-at-start.json"
        repo="$HOME/flakeos/modules/programs/noctalia/settings.json"

        live() { noctalia-shell ipc call state all | jq '.settings'; }

        case "''${1:-}" in
          --snapshot)
            sleep 5 # noctalia fills in the widget defaults a moment after start
            live > "$snapshot"
            exit 0
            ;;
          "" | --save) ;;
          *)
            echo "usage: noctalia-changes [--save]" >&2
            exit 1
            ;;
        esac

        if [ ! -s "$snapshot" ]; then
          echo "No snapshot yet. Noctalia takes one when it starts: log out and in again." >&2
          exit 1
        fi

        # changed(new; old): only the parts of new that differ from old.
        # Objects are compared key by key; anything else (numbers, text,
        # lists like the bar widgets) is kept whole when it differs.
        changes=$(live | jq --slurpfile old "$snapshot" '
          def changed($new; $old):
            if ($new | type) == "object" and ($old | type) == "object" then
              reduce ($new | keys_unsorted[]) as $k ({};
                changed($new[$k]; $old[$k]) as $c
                | if $c == null then . else .[$k] = $c end)
              | if . == {} then null else . end
            elif $new == $old then null
            else $new
            end;
          changed(.; $old[0]) // {}')

        if [ "$changes" = "{}" ]; then
          echo "Nothing changed in the settings GUI (since noctalia started or the last --save)."
          exit 0
        fi

        echo "$changes"

        if [ "''${1:-}" = --save ]; then
          merged=$(jq --argjson changes "$changes" '. * $changes' "$repo")
          printf '%s\n' "$merged" > "$repo"
          live > "$snapshot"
          echo
          echo "Added to $repo."
          echo "Check it with 'git diff', then rebuild (nrs)."
        fi
      '';
    };
  in {
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
    environment.systemPackages = [
      pkgs.brightnessctl # brightness OSD / keys
      noctaliaChanges
    ];
  };
}
