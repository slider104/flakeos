{
  description = "flakeos - a minimal, fully wrapped NixOS configuration for zeus and hermes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Flake structure: every *.nix file under ./modules is imported
    # automatically as a flake-parts module (the "dendritic" pattern).
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";

    # Wrapping: program + its config become one package (our home-manager replacement).
    wrapper-modules = {
      url = "github:nix-community/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative partitioning, only used when (re)installing a machine.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./modules);
}
