{
  self,
  inputs,
  ...
}: {
  # hermes: laptop.
  flake.nixosConfigurations.hermes = inputs.nixpkgs.lib.nixosSystem {
    modules = with self.nixosModules; [
      # host hardware
      hermes-disko
      hermes-hardware

      # modules/programs
      base
      bluetooth
      desktop

      # gaming
      libreoffice
      rustdesk

      # users
      slider

      ({lib, ...}: {
        networking.hostName = "hermes";
        services.greetd.settings.initial_session.user = "slider"; # autologin

        # Bluetooth starts switched off (saves battery). The service still
        # runs, so the Bluetooth button in the bar turns it on for the
        # session; after a reboot it is off again. mkForce wins over the
        # shared `powerOnBoot = true` in system/bluetooth.nix.
        hardware.bluetooth.powerOnBoot = lib.mkForce false;

        # noctalia: the shared bar (programs/noctalia/config.toml) plus
        # Bluetooth and Battery on the right. A list can't be partly
        # overridden, so this is the whole right-hand lane; mkForce makes it
        # win over config.toml. Keep it in sync when the shared list changes.
        wrappers.noctalia.settings.bar.main.end = lib.mkForce [
          "tray"
          "notifications"
          "bluetooth"
          "battery"
          "volume"
          "brightness"
          "clock"
          "control-center"
        ];

        # The NixOS release this machine was first installed with. Never change it.
        system.stateVersion = "26.11";
      })
    ];
  };
}
