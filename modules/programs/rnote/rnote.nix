{
  # Rnote: handwritten notes and sketches (made for a pen/tablet, works with
  # a mouse). Not wrapped: it keeps its settings itself (GSettings/dconf).
  # It registers itself for its own .rnote files.
  flake.nixosModules.rnote = {pkgs, ...}: {
    environment.systemPackages = [pkgs.rnote];
  };
}
