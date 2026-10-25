{
  description = "flakeos - a minimal, fully wrapped NixOS configuration for zeus and hermes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # The escape hatch for packages that are broken or gone on unstable: a
    # second nixpkgs to take single packages from. Nothing uses it until a
    # line in modules/system/stable.nix says so.
    #
    # This is *not* the stable release but a pinned unstable commit: the last
    # one that still had noctalia-shell 4.x (removed on 2026-10-22). A package
    # taken from here brings its own dependencies along, and for anything that
    # draws on screen those have to match the system's: the graphics driver in
    # /run/opengl-driver comes from the system's nixpkgs, and it is loaded into
    # the borrowed package's process. The release branch is months behind, so
    # its glibc is older than the driver needs, the driver fails to load, and
    # the program starts but renders nothing. A commit days old shares nearly
    # everything with the system and avoids that. See system/stable.nix.
    nixpkgs-stable.url = "github:nixos/nixpkgs/55bfb4d7437bd4e09ab7cba58a43bd68eb310044";

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
