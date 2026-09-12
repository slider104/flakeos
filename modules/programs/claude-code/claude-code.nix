{
  # Claude Code (`claude`). Not wrapped: login, settings and memory are its own
  # state, in ~/.claude. Unfree, allowed in system/nix.nix. Updates come from
  # nixpkgs (`nup`); the nixpkgs package already turns off the self-updater.
  flake.nixosModules.claude-code = {pkgs, ...}: {
    environment.systemPackages = [pkgs.claude-code];
  };
}
