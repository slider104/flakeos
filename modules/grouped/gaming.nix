{self, ...}: {
  # Gaming: Steam (+ Proton-GE), performance tools and other launchers.
  flake.nixosModules.gaming = {
    imports = with self.nixosModules; [
      steam
      gamemode
      gamescope
      mangohud
      prismlauncher
      lutris
    ];
  };
}
