{
  self,
  inputs,
  ...
}: {
  # zeus: gaming desktop.
  flake.nixosConfigurations.zeus = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      zeus-hardware
      zeus-disko

      base
      desktop
      gaming
      openrgb

      slider

      {
        networking.hostName = "zeus";
        services.greetd.settings.initial_session.user = "slider"; # autologin

        # The 1.9 TB data drive, mounted at boot. `nofail`: boot continues
        # even if the drive is missing or broken.
        fileSystems."/mnt/data" = {
          device = "/dev/disk/by-uuid/0574158e-46bd-43a8-bd49-8e75304ce6f3";
          fsType = "ext4";
          options = ["nofail"];
        };

        # The NixOS release this machine was first installed with. Never change it.
        system.stateVersion = "26.11";
      }
    ];
  };
}
