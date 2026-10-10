{inputs, ...}: {
  flake.nixosModules.nix = {
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
    };

    # Delete old generations weekly. Their boot menu entries disappear at the
    # next rebuild (`nrs`/`nrb`), not right away.
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Deduplicate the store: files that are identical in several packages
    # become hardlinks to one copy. Runs as its own job (nightly).
    #
    # The older `auto-optimise-store` setting did the same work during every
    # build instead, while holding a lock that the rest of the store waits
    # on - a known cause of builds that seem to hang for minutes.
    nix.optimise.automatic = true;

    # `nix shell nixpkgs#foo` uses the same nixpkgs the system was built from.
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    nix.nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    nixpkgs.config.allowUnfree = true; # Steam
  };
}
