{
  # Fedora Media Writer: writes ISO images (NixOS, Fedora, ...) to USB sticks.
  # Nothing to configure. It writes to the stick through udisks2, which is
  # already on (Thunar uses it too); the password prompt comes from polkit.
  flake.nixosModules.mediawriter = {pkgs, ...}: {
    environment.systemPackages = [pkgs.mediawriter];
  };
}
