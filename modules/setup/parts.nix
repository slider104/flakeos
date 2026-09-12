{
  inputs,
  lib,
  ...
}: {
  # How the flake itself is wired together. Nothing in here ends up on a machine.

  imports = [
    # Adds `flake.wrappers.<name>`: every wrapper defined there automatically
    # becomes `packages.<system>.<name>` (so `nix run .#<name>` works) and gets
    # an `.install` NixOS module we import in programs/*.
    inputs.wrapper-modules.flakeModules.wrappers
  ];

  # A place for small helper functions shared between files (see setup/disko.nix).
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  config = {
    systems = ["x86_64-linux"];

    perSystem = {pkgs, ...}: {
      # `nix fmt .` formats the whole repo (the `.` is needed).
      formatter = pkgs.alejandra;
    };
  };
}
