{config, ...}: let
  theme = config.theme; # the palette (modules/system/theme/palette.nix)
  wrappers = config.flake.wrappers;
in {
  # BLUEPRINT: a program wrapped with a READY-MADE module from nix-wrapper-modules.
  # Copy this folder to modules/programs/<name>/ and replace every `example`.
  #
  # Is there a ready-made module for your program? Check the list:
  #   https://nix-community.github.io/nix-wrapper-modules/
  # (in this repo: alacritty, niri, noctalia-shell, zsh, git, btop, mpv, imv)
  # If not, use blueprints/programs/wrapped-custom/ instead.
  flake.wrappers.example = {wlib, ...}: {
    imports = [wlib.wrapperModules.example];

    # Modules take their config in one of two ways; the docs page of the
    # module lists its options.
    #
    # a) As Nix. The module turns it into the program's own format, so the
    #    shape follows that format (sections for INI, tables for TOML, ...).
    #    Good when you want palette colours. See programs/alacritty/ (TOML)
    #    and programs/imv/ (INI) for real ones.
    settings = {
      # colors.background = theme.bg;
    };

    # b) As a native config file next to this one. The option name depends on
    #    the module, e.g. `"config.kdl".path` (niri), `"mpv.conf".path` (mpv),
    #    `configFile.path` (git).
    # "example.conf".path = ./example.conf;
  };

  # Installs the wrapped program. Add `example` to a file in grouped/ or a host.
  flake.nixosModules.example = {
    imports = [wrappers.example.install];
    wrappers.example.enable = true;
  };
}
