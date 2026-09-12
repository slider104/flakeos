{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # zsh, wrapped: its ZDOTDIR points into the store, so the zshrc next to this
  # file is the only one used. ~/.zshrc is ignored.
  flake.wrappers.zsh = {
    wlib,
    pkgs,
    ...
  }: {
    imports = [wlib.wrapperModules.zsh];

    # Skip NixOS's /etc/zshrc (its own prompt and compinit), we have ours.
    # /etc/zshenv is still read; it puts NixOS's PATH in place.
    skipGlobalRC = true;

    zshrc.path = ./zshrc;
    # Sourced after zshrc. syntax-highlighting has to come last.
    zshrc.content = ''
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    '';
  };

  flake.nixosModules.zsh = {config, ...}: {
    imports = [wrappers.zsh.install];

    # NixOS's zsh module with our wrapped zsh as the package: it adds the
    # wrapper to /etc/shells and PATH, and writes /etc/zshenv.
    # Users pick it with `shell = config.programs.zsh.package;`.
    programs.zsh = {
      enable = true;
      package = config.wrappers.zsh.wrapper;
    };
  };
}
