{lib, ...}: {
  # THE palette. Colours for alacritty, niri, noctalia, Zed, MangoHud, imv,
  # btop (via the terminal) and the TTY come from here.
  # (Not your RGB lights: they have their own colour, see programs/openrgb/.)
  # Change a value, rebuild, and they all follow.
  #
  # The values are GNOME's dark Adwaita, as used by adw-gtk3-dark (theme.nix),
  # so the wrapped programs look like the GTK apps next to them.
  #
  # This is a flake-level option (not a NixOS one), so wrapped packages can
  # read it too: any module file can use `config.theme` at the top level.
  options.theme = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "The flakeos colour palette, fonts and cursor.";
  };

  config.theme = {
    # Adwaita dark (names in brackets = the adw-gtk3-dark colour it copies).
    bg = "#1d1d20"; # content: terminal, editor          (view_bg_color)
    surface = "#2e2e32"; # bar, panels, title bars       (headerbar/sidebar_bg_color)
    overlay = "#36363a"; # popups, hovered rows          (popover/dialog_bg_color)
    border = "#434347"; #                                (borders)
    muted = "#919193"; # secondary text                  (unfocused fg)
    text = "#ffffff"; #                                  (window_fg_color)
    accent = "#3584e4"; # focus ring, selection          (accent_bg_color, GNOME blue)
    onAccent = "#ffffff"; # text drawn on the accent     (accent_fg_color)
    error = "#ed333b"; #                                 (GNOME red)

    # The 16 terminal colours (also used for the TTY): GNOME Console's
    # default palette, built from the same GNOME colours.
    normal = {
      black = "#241f31";
      red = "#c01c28";
      green = "#2ec27e";
      yellow = "#f5c211";
      blue = "#1e78e4";
      magenta = "#9841bb";
      cyan = "#0ab9dc";
      white = "#c0bfbc";
    };
    bright = {
      black = "#5e5c64";
      red = "#ed333b";
      green = "#57e389";
      yellow = "#f8e45c";
      blue = "#51a1ff";
      magenta = "#c061cb";
      cyan = "#4fd2fd";
      white = "#f6f5f4";
    };

    font = {
      sans = "Noto Sans";
      mono = "JetBrainsMono Nerd Font";
      size = 14;
    };

    cursor = {
      name = "Bibata-Modern-Classic";
      size = 26;
    };

    icons = "Papirus-Dark";
  };
}
