{config, ...}: let
  wrappers = config.flake.wrappers;
in {
  # git, wrapped with the gitconfig next to this file.
  flake.wrappers.git = {wlib, ...}: {
    imports = [wlib.wrapperModules.git];
    configFile.path = ./gitconfig;
  };

  flake.nixosModules.git = {
    imports = [wrappers.git.install];
    wrappers.git.enable = true;
  };
}
