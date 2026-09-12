{
  # Steam. Not wrapped: Steam manages its own settings and library.
  # The NixOS module also sets up 32-bit graphics and controller udev rules.
  flake.nixosModules.steam = {pkgs, ...}: {
    programs.steam = {
      enable = true;
      # Proton-GE shows up in Steam > game > Properties > Compatibility.
      extraCompatPackages = [pkgs.proton-ge-bin];
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
}
