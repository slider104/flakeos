{
  # Password prompts for GUI apps ("Authentication required" when Thunar mounts
  # a drive, gamemode changes the CPU governor, ...). Without a polkit agent
  # those actions silently fail under niri. The GNOME agent is GTK3, so it
  # uses our dark theme. Started with the niri session.
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
