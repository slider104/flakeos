{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # BLUEPRINT: a program wrapped by hand, for when there is NO ready-made module.
  # Copy this folder to modules/programs/<name>/ and replace every `example`.
  # Real example in this repo: programs/mangohud/.
  #
  # First find out how the program can be told where its config is.
  # Look in `man example` or `example --help` for either:
  #   - a command-line flag, like `--config <file>`
  #   - an environment variable, like `EXAMPLE_CONFIG=<file>`
  # If it has neither, it can't be wrapped. Install it plain instead
  # (blueprints/programs/plain/).
  flake.wrappers.example = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.example;

    # Either a flag ...
    flags."--config" = ./example.conf;

    # ... or an environment variable. Use one of the two.
    # env.EXAMPLE_CONFIG = "${./example.conf}";
  };

  flake.nixosModules.example = {
    imports = [wrappers.example.install];
    wrappers.example.enable = true;
  };
}
