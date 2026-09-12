{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # bat: `cat` with syntax highlighting, line numbers and git changes
  # (`bat file.nix`). It pages long files through `less` (q quits).
  #
  # Wrapped with one setting: the "ansi" theme. It paints with the terminal's
  # 16 colours instead of its own, and those come from the palette (via
  # alacritty), so bat matches everything else.
  # Try other themes with `bat --list-themes`, and one-off with `--theme <name>`.
  flake.wrappers.bat = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.modules.default];
    package = pkgs.bat;
    env.BAT_THEME = "ansi";
  };

  flake.nixosModules.bat = {
    imports = [wrappers.bat.install];
    wrappers.bat.enable = true;
  };
}
