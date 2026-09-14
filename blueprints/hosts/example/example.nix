{
  self,
  inputs,
  ...
}: {
  # BLUEPRINT: a machine.
  # How to use it: blueprints/README.md
  # Real ones in this repo: hosts/zeus/, hosts/hermes/.
  #
  # Build or switch with:  sudo nixos-rebuild switch --flake .#example
  # (or just `nrs` on the machine itself; it's picked by hostname).
  flake.nixosConfigurations.example = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      # This machine (hardware.nix + disko.nix next to this file).
      example-hardware
      example-disko

      # Bundles from grouped/. Remove what the machine doesn't need.
      base
      desktop
      gaming

      # Single programs just for this machine, e.g.:
      # openrgb

      # Users from users/.
      slider

      {
        networking.hostName = "example"; # must match the name after `#`
        services.greetd.settings.initial_session.user = "slider"; # autologin

        # The NixOS release this machine was first installed with.
        # Set it once at install time (current: "26.11"), then never change it.
        system.stateVersion = "26.11";
      }
    ];
  };
}
