{
  self,
  inputs,
  ...
}: {
  # hermes: laptop.
  flake.nixosConfigurations.hermes = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      hermes-hardware
      hermes-disko

      base
      desktop
      # gaming

      slider

      {
        networking.hostName = "hermes";
        services.greetd.settings.initial_session.user = "slider"; # autologin

        # The NixOS release this machine was first installed with. Never change it.
        system.stateVersion = "26.11";
      }
    ];
  };
}
