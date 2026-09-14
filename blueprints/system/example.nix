{
  # BLUEPRINT: a system setting (a service, hardware support, a kernel option, ...).
  # How to use it: blueprints/README.md
  # One topic per file, named after the topic (like audio.nix or bluetooth.nix).
  # Real ones in this repo: system/audio.nix, system/bluetooth.nix.
  #
  # Anything you'd find on https://search.nixos.org/options goes in here.
  flake.nixosModules.example = {pkgs, ...}: {
    services.example.enable = true;

    # Tools the setting needs, if any:
    environment.systemPackages = [pkgs.example-tools];
  };
}
