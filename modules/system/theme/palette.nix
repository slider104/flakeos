{lib, ...}: {
  # THE palette. Colours for alacritty, niri, noctalia, Zed, MangoHud, imv,
  # btop (via the terminal), the TTY and your RGB come from here.
  # Change a value, rebuild, and they all follow.
  # (GTK and Qt apps use standard dark Adwaita instead, see theme.nix.)
  #
  # This is a flake-level option (not a NixOS one), so wrapped packages can
  # read it too: any module file can use `config.theme` at the top level.
  options.theme = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "The flakeos colour palette, fonts and cursor.";
  };

  config.theme = {
    # Near-black neutral.
    bg = "#0b0b0c"; # windows, terminal
    surface = "#141416"; # bar, panels, popups
    overlay = "#1c1c1f"; # headerbars, hovered/selected rows
    border = "#2a2a2e";
    muted = "#8a8a91"; # secondary text
    text = "#d0d0d0";
    accent = "#7fc8ff"; # focus ring, selection, RGB
    onAccent = "#0b0b0c"; # text drawn on top of the accent
    error = "#e5737a";

    # The 16 terminal colours (also used for the TTY).
    normal = {
      black = "#1c1c1f";
      red = "#e5737a";
      green = "#9fcf8a";
      yellow = "#e6c07b";
      blue = "#7fc8ff";
      magenta = "#c3a6ff";
      cyan = "#7fe0d8";
      white = "#c8c8c8";
    };
    bright = {
      black = "#4a4a50";
      red = "#ff8a91";
      green = "#b5e5a0";
      yellow = "#f5d494";
      blue = "#a3d8ff";
      magenta = "#d6c2ff";
      cyan = "#9ff0e8";
      white = "#ececec";
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
