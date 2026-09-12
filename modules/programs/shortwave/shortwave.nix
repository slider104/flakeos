{
  # Shortwave: internet radio (stations from radio-browser.info). Not wrapped:
  # your library of stations is its own state, in ~/.local/share/Shortwave.
  flake.nixosModules.shortwave = {pkgs, ...}: {
    environment.systemPackages = [pkgs.shortwave];
  };
}
