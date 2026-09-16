{
  # ydotool + Autoclicker: clicks the mouse for you, in every window
  # (Wayland apps, X11 apps, games).
  #
  # How it works:
  #   1. `ydotoold` (a NixOS service) creates a fake mouse + keyboard in the
  #      kernel. niri sees it like a real USB mouse, so its clicks work
  #      everywhere. Only members of the `ydotool` group may use it
  #      (users/slider.nix).
  #   2. `ydotool click ...` tells ydotoold what to click.
  #   3. `autoclicker` (autoclicker.py next to this file) is a small GTK
  #      window on top: clicks per second, button, how many clicks, a start
  #      delay. It's in the launcher (Mod+Space, "Autoclicker"). Nothing
  #      clicks until you press Start; Stop or closing the window ends it.
  #   4. A start/stop key can be set in the window (F8, a mouse side
  #      button, ...). It works in every window while the Autoclicker is
  #      open: the app reads the keyboards and mice from /dev/input, which
  #      needs the `input` group (users/slider.nix).
  #
  # The settings are saved in ~/.config/autoclicker/settings.json.
  # Some online games treat fast autoclicking as cheating.
  flake.nixosModules.ydotool = {
    config,
    pkgs,
    lib,
    ...
  }: let
    # Python with the libraries autoclicker.py imports.
    python = pkgs.python3.withPackages (ps: [
      ps.pygobject3 # GTK 4 + libadwaita
      ps.evdev # reads the start/stop key from /dev/input
      # Type descriptions of GTK 4, only for Zed's Python checker (the
      # package describes GTK 3 unless told otherwise).
      (ps.pygobject-stubs.overridePythonAttrs {
        env.PYGOBJECT_STUB_CONFIG = "Gtk4,Gdk4,Soup3";
      })
    ]);

    autoclicker = pkgs.stdenv.mkDerivation {
      pname = "autoclicker";
      version = "1.0";
      dontUnpack = true;

      # wrapGAppsHook4 turns bin/autoclicker into a wrapper that finds GTK 4
      # and libadwaita; the python above runs the script itself.
      nativeBuildInputs = [pkgs.wrapGAppsHook4 pkgs.gobject-introspection];
      buildInputs = [pkgs.gtk4 pkgs.libadwaita python];

      installPhase = ''
        install -Dm755 ${./autoclicker.py} $out/bin/autoclicker
        install -Dm644 ${./autoclicker.desktop} $out/share/applications/org.flakeos.Autoclicker.desktop
      '';

      # The wrapper also brings ydotool and the socket ydotoold listens on.
      preFixup = ''
        gappsWrapperArgs+=(
          --prefix PATH : ${lib.makeBinPath [pkgs.ydotool]}
          --set YDOTOOL_SOCKET ${config.environment.variables.YDOTOOL_SOCKET}
        )
      '';

      meta.mainProgram = "autoclicker";
    };
  in {
    # The ydotoold service, the `ydotool` group and the `ydotool` command.
    programs.ydotool.enable = true;

    environment.systemPackages = [autoclicker];

    # A fixed path to that python, so Zed's Python checker (basedpyright)
    # finds gi and evdev while you edit autoclicker.py. Without it, Zed
    # marks those imports as errors (the app itself works either way).
    # pyrightconfig.json in the repo root points there.
    environment.etc."autoclicker/python".source = python;
  };
}
