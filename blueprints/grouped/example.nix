{self, ...}: {
  # BLUEPRINT: a bundle of modules a host can pick with one name.
  # How to use it: blueprints/README.md
  # Real ones in this repo: grouped/desktop.nix, grouped/gaming.nix.
  #
  # A bundle only lists names. Each name is a `flake.nixosModules.<name>`
  # defined somewhere in modules/ (programs/, system/, or another bundle).
  flake.nixosModules.example = {
    imports = with self.nixosModules; [
      # system/
      audio

      # programs/
      mpv
      imv
    ];
  };
}
