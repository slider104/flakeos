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

    # Split locks are slow memory operations some games (and Steam) do. By
    # default the kernel punishes them by pausing the thread for a moment,
    # which can make games stutter. Turn that off, like SteamOS does.
    # The "split lock detection" lines in the kernel log stay (just a warning).
    boot.kernel.sysctl."kernel.split_lock_mitigate" = 0;
  };
}
