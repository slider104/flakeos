{inputs, ...}: {
  # BLUEPRINT: a program that is NOT in nixpkgs but ships its own flake.
  # How to use it: blueprints/README.md
  # Always check nixpkgs first (https://search.nixos.org/packages): one less
  # input to keep updated.
  #
  # Step 1: add the flake to the `inputs` in flake.nix:
  #
  #   example = {
  #     url = "github:someone/example";
  #     inputs.nixpkgs.follows = "nixpkgs"; # use our nixpkgs, if it has one
  #   };
  #
  # Step 2: `nix flake lock` (or just rebuild) to pin it in flake.lock.
  #
  # Step 3: install its package. Flakes publish packages per CPU architecture,
  # so pick the one for this machine:
  flake.nixosModules.example = {pkgs, ...}: {
    environment.systemPackages = [
      inputs.example.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  # Some flakes offer a NixOS module instead; then it's:
  #   flake.nixosModules.example = {
  #     imports = [inputs.example.nixosModules.default];
  #     programs.example.enable = true;
  #   };
}
