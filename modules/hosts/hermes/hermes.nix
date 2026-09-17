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
      bluetooth
      # gaming
      rustdesk

      slider

      ({lib, ...}: {
        networking.hostName = "hermes";
        services.greetd.settings.initial_session.user = "slider"; # autologin

        # Bluetooth starts switched off (saves battery). The service still
        # runs, so the Bluetooth button in the bar turns it on for the
        # session; after a reboot it is off again. mkForce wins over the
        # shared `powerOnBoot = true` in system/bluetooth.nix.
        hardware.bluetooth.powerOnBoot = lib.mkForce false;

        # noctalia: the shared bar (programs/noctalia/settings.json) plus
        # Bluetooth and Battery on the right. A list can't be partly
        # overridden, so this is the whole right side; mkForce makes it win
        # over settings.json. Keep it in sync when the shared list changes.
        wrappers.noctalia-shell.settings.bar.widgets.right = lib.mkForce [
          {id = "Tray";}
          {id = "NotificationHistory";}
          {id = "Bluetooth";}
          {id = "Battery";}
          {id = "Volume";}
          {id = "Brightness";}
          {id = "Clock";}
          {
            id = "ControlCenter";
            icon = "power";
            enableColorization = true;
            colorizeSystemIcon = "primary";
          }
        ];

        # The NixOS release this machine was first installed with. Never change it.
        system.stateVersion = "26.11";
      })
    ];
  };
}
