{
  # fastfetch: system info with the NixOS logo. Runs whenever alacritty
  # opens (see programs/alacritty/alacritty.toml), or type `fastfetch`.
  # Not wrapped: we use its default look, so there's no config to bake in.
  flake.nixosModules.fastfetch = {pkgs, ...}: {
    environment.systemPackages = [pkgs.fastfetch];
  };
}
