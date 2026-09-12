{
  # Standard home folders (Downloads, Pictures, Videos, ...), created at login
  # if missing. Thunar's sidebar and Firefox's downloads use them.
  #
  # Which app opens which file type is set in each program's own module
  # (`xdg.mime.defaultApplications`), e.g. programs/mpv/mpv.nix for videos.
  flake.nixosModules.xdg = {pkgs, ...}: {
    environment.systemPackages = [pkgs.xdg-user-dirs]; # runs via its autostart entry
    xdg.mime.enable = true;
  };
}
