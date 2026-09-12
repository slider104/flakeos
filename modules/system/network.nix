{
  flake.nixosModules.network = {
    networking.networkmanager.enable = true; # noctalia's Wi-Fi menu talks to it
    networking.firewall.enable = true;
  };
}
