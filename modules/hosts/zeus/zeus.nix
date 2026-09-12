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
        # `x-gvfs-show`: list it in Thunar's side panel under Devices (drives
        # mounted outside /media or /run/media are hidden otherwise), named
        # by `x-gvfs-name`. Both are only read by Thunar/GVfs, not by mount.
        fileSystems."/mnt/data" = {
          device = "/dev/disk/by-uuid/0574158e-46bd-43a8-bd49-8e75304ce6f3";
          fsType = "ext4";
          options = ["nofail" "x-gvfs-show" "x-gvfs-name=Data"];
        };

        # The NixOS release this machine was first installed with. Never change it.
        system.stateVersion = "26.11";
      }
    ];
  };
}
