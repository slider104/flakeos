{
  # Login: greetd starts niri directly after boot (autologin), without a login screen.
  #
  # Which user gets logged in is set per host:
  #   services.greetd.settings.initial_session.user = "slider";
  #
  # `initial_session` runs once per boot. If you log out of niri, you land on
  # the small text login screen (`default_session`) instead of a black screen.
  flake.nixosModules.login = {
    pkgs,
    lib,
    ...
  }: {
    services.greetd = {
      enable = true;
      settings = {
        initial_session.command = "niri-session";
        default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd niri-session";
          user = "greeter";
        };
      };
    };
  };
}
