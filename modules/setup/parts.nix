{
  config,
  inputs,
  lib,
  moduleLocation,
  ...
}: {
  # How the flake itself is wired together. Nothing in here ends up on a machine.

  imports = [
    # Adds `flake.wrappers.<name>`: every wrapper defined there automatically
    # becomes `packages.<system>.<name>` (so `nix run .#<name>` works) and gets
    # an `.install` NixOS module we import in programs/*.
    inputs.wrapper-modules.flakeModules.wrappers
  ];

  # `flake.nixosModules.<name>`, like flake-parts' own version, plus a `key`.
  # The key is how NixOS notices it has seen a module already. Without it, a
  # module listed twice (in two bundles, or in a bundle and a host) is loaded
  # twice, and that breaks the build. With it, listing twice is harmless.
  disabledModules = ["${inputs.flake-parts}/modules/nixosModules.nix"];
  options.flake.nixosModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = {};
    apply = lib.mapAttrs (name: module: {
      _class = "nixos";
      _file = "${toString moduleLocation}#nixosModules.${name}";
      key = "${toString moduleLocation}#nixosModules.${name}";
      imports = [module];
    });
  };

  # A place for small helper functions shared between files (see setup/disko.nix).
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config = {
    systems = [
      "x86_64-linux"
      "aarch64-linux"
    ];

    perSystem = {
      system,
      pkgs,
      ...
    }: {
      # The pkgs the flake's *own* outputs are built from: the wrappers as
      # packages (`nix build .#noctalia-shell`, `nix run .#zsh`) and the
      # formatter. A host does not use this one - it gets its own pkgs from
      # its nixosSystem - so without saying it twice the two would differ.
      # Both lines below mirror what the hosts have, so a package built by
      # hand is the same one the system installs:
      #   allowUnfree    system/nix.nix
      #   overlays       system/stable.nix (the escape hatch)
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [config.flake.overlays.stable];
      };

      # `nix fmt .` formats the whole repo (the `.` is needed).
      formatter = pkgs.alejandra;
    };
  };
}
