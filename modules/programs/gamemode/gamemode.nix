{
  # GameMode: boosts CPU/GPU while a game runs.
  # Steam launch options: `gamemoderun %command%`
  flake.nixosModules.gamemode = {
    programs.gamemode.enable = true;
  };
}
