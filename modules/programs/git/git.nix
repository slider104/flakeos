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

    # Trust GitHub's SSH host key up front. Otherwise the first push on a
    # fresh install asks "Are you sure you want to continue connecting?",
    # which only a terminal can answer (Zed just fails). The key is the one
    # GitHub publishes: docs.github.com → "GitHub's SSH key fingerprints".
    programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
  };
}
