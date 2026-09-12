{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;
  noHash = builtins.substring 1 6; # MangoHud wants bare hex
in {
  # MangoHud, wrapped: `mangohud` always sets MANGOHUD_CONFIGFILE to our file.
  # There is no ready-made module for it, so this is the generic form: a
  # package + the environment variables it should always start with.
  flake.wrappers.mangohud = {
    wlib,
    pkgs,
    ...
  }: let
    # MangoHud.conf + palette colours. Later lines win in MangoHud's format.
    configFile = pkgs.writeText "MangoHud.conf" ''
      ${builtins.readFile ./MangoHud.conf}
      # --- palette (modules/system/theme/palette.nix) ---
      background_color=${noHash theme.bg}
      text_color=${noHash theme.text}
      gpu_color=${noHash theme.accent}
      cpu_color=${noHash theme.bright.cyan}
      vram_color=${noHash theme.bright.magenta}
      ram_color=${noHash theme.bright.magenta}
      engine_color=${noHash theme.accent}
      frametime_color=${noHash theme.bright.green}
    '';
  in {
    imports = [wlib.modules.default];
    package = pkgs.mangohud;
    env.MANGOHUD_CONFIGFILE = "${configFile}";
  };

  flake.nixosModules.mangohud = {
    imports = [wrappers.mangohud.install];
    wrappers.mangohud.enable = true;
  };
}
