{
  # Thunar (file manager). Not wrapped: Thunar stores its preferences in xfconf
  # (a small settings database), not in a config file we could point it at.
  # It picks up the dark GTK theme on its own.
  flake.nixosModules.thunar = {
    pkgs,
    lib,
    ...
  }: {
    programs.thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin # right-click > extract / compress
        thunar-volman # auto-mount USB sticks
      ];
    };
    programs.xfconf.enable = true; # lets Thunar remember its settings
    services.gvfs.enable = true; # trash, mounting, network places
    services.tumbler.enable = true; # thumbnails

    environment.systemPackages = [pkgs.xarchiver]; # used by the archive plugin

    # Right-click > "Open Terminal Here" (see uca.xml next to this file).
    environment.etc."xdg/Thunar/uca.xml".source = ./uca.xml;

    # Folders open in Thunar, archives in xarchiver.
    xdg.mime.defaultApplications =
      {"inode/directory" = "thunar.desktop";}
      // lib.genAttrs [
        "application/zip"
        "application/x-7z-compressed"
        "application/x-rar"
        "application/vnd.rar"
        "application/x-tar"
        "application/x-compressed-tar"
        "application/gzip"
      ] (_: "xarchiver.desktop");
  };
}
