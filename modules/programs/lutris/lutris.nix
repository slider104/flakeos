{
  # Lutris (Battle.net, GOG installers, emulators, ...). Not wrapped: it
  # manages its games, runners and settings itself in ~/.local/share/lutris.
  flake.nixosModules.lutris = {pkgs, ...}: {
    environment.systemPackages = [pkgs.lutris];
  };
}
