{
  # Rnote: handwritten notes and sketches (made for a pen/tablet, works with
  # a mouse). Not wrapped: it has no config file to point it at. Everything -
  # pen widths and colours, the page format, the toolbar - lives in dconf,
  # the settings database GTK apps write into.
  #
  # So the dconf/ folder next to this file holds those settings, and they are
  # installed as *defaults*: rnote starts out the way you set it up, and
  # changing something in rnote still works and wins from then on. To keep a
  # change you made: `dconf-changes rnote --save` (see README.md, "Keeping GTK
  # app settings (dconf)").
  #
  # It registers itself for its own .rnote files.
  flake.nixosModules.rnote = {pkgs, ...}: {
    environment.systemPackages = [pkgs.rnote];

    # keyfiles wants a folder, and every file in it is a dconf keyfile -
    # exactly the format `dconf dump` prints, so nothing is translated.
    programs.dconf.profiles.user.databases = [{keyfiles = [./dconf];}];
  };
}
