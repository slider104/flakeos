{
  # Password prompts for GUI apps ("Authentication required" when Thunar mounts
  # a drive, gamemode changes the CPU governor, ...). Without a polkit agent
  # those actions silently fail under niri. The GNOME agent is GTK3, so it
  # uses our dark theme. Started with the niri session.
  #
  # Noctalia 5 can be an agent itself (`polkit_agent` in its config.toml),
  # but polkit allows only one per session: whichever starts second logs
  # "An authentication agent already exists for the given subject" and does
  # nothing. This one wins, so noctalia's stays off (its default).
  flake.nixosModules.polkit = {pkgs, ...}: {
    security.polkit.enable = true;

    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit authentication agent";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
