{
  # gamescope: runs a game in its own micro-compositor (fixed resolution,
  # upscaling, frame limiting). Steam launch options, e.g.:
  #   gamescope -W 2560 -H 1440 -f -- %command%
  flake.nixosModules.gamescope = {
    programs.gamescope.enable = true;
  };
}
