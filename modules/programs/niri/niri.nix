{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
in {
  # niri, wrapped: the binary always starts with our config (NIRI_CONFIG points
  # into the store). ~/.config/niri is never read.
  #
  # Try it anywhere with `nix run .#niri`, or check the config with
  # `nix build .#niri` (the build runs `niri validate`).
  flake.wrappers.niri = {
    wlib,
    pkgs,
    ...
  }: let
    # Generated from the palette, pulled in by `include "theme.kdl"`.
    themeKdl = pkgs.writeText "theme.kdl" ''
      layout {
          background-color "${theme.bg}"
          focus-ring {
              active-color "${theme.accent}"
              inactive-color "${theme.border}"
          }
      }
      overview {
          backdrop-color "${theme.bg}"
      }
      cursor {
          xcursor-theme "${theme.cursor.name}"
          xcursor-size ${toString theme.cursor.size}
      }
    '';

    # config.kdl and theme.kdl must sit in the same directory for the include.
    configDir = pkgs.runCommand "niri-config" {} ''
      mkdir $out
      cp ${./config.kdl} $out/config.kdl
      cp ${themeKdl} $out/theme.kdl
    '';
  in {
    imports = [wlib.wrapperModules.niri];

    # The wrapper generates its own config file (niri-config.kdl inside the
    # package). niri starts with it, `niri validate` checks it at build time,
    # and after every rebuild the running niri reloads it (niri.service
    # ExecReload). So that file must be OUR config: it just includes it.
    #
    # Don't use `"config.kdl".path` instead: niri would start with our file,
    # but the reload after a rebuild would still load the wrapper's own,
    # EMPTY file (all key binds gone, default looks until the next login).
    "config.kdl".content = ''
      include "${configDir}/config.kdl"
    '';
  };

  flake.nixosModules.niri = {
    config,
    lib,
    pkgs,
    ...
  }: {
    imports = [wrappers.niri.install];

    programs.niri = {
      enable = true;
      package = config.wrappers.niri.wrapper;
      useNautilus = false; # file dialogs come from the GTK portal instead
    };
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

    # Electron/Chromium apps run as native Wayland apps instead of via X11.
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    environment.systemPackages = with pkgs; [
      xwayland-satellite # X11 apps (Steam!) - niri starts it on demand
      wl-clipboard
      playerctl # media keys

      # XWayland has its own clipboard, and xwayland-satellite does not carry
      # what an X11 program copies over to niri, nor the other way round. This
      # mirrors the two in both directions - X11 programs in general, and the
      # clipboard of a virtual machine (programs/virt-manager/README.md), which
      # travels through XWayland on both machines. The two comparisons stop the
      # halves from bouncing the same value back and forth forever.
      (writeShellScriptBin "niri-clipboard-bridge" ''
        export PATH=${lib.makeBinPath [wl-clipboard xclip clipnotify]}:$PATH
        export DISPLAY=''${DISPLAY:-:0}

        # niri -> XWayland
        while :; do
          wl-paste --type text --watch sh -c '
            new=$(cat)
            [ "$new" = "$(xclip -selection clipboard -o -t UTF8_STRING 2>/dev/null)" ] && exit 0
            printf %s "$new" | xclip -selection clipboard -i
          '
          sleep 1
        done &

        # XWayland -> niri
        while :; do
          clipnotify -s clipboard 2>/dev/null || { sleep 2; continue; }
          new=$(xclip -selection clipboard -o -t UTF8_STRING 2>/dev/null) || continue
          [ -z "$new" ] && continue
          [ "$new" = "$(wl-paste --no-newline 2>/dev/null)" ] && continue
          printf %s "$new" | wl-copy
        done
      '')
    ];
  };
}
