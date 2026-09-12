{inputs, ...}: {
  flake.nixosModules.nix = {
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
      trusted-users = ["root" "@wheel"];
    };

    # Delete old generations weekly (this also removes their boot entries).
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # `nix shell nixpkgs#foo` uses the same nixpkgs the system was built from.
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    nixpkgs.config.allowUnfree = true; # Steam
  };
}
