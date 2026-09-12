{
  # RustDesk: remote desktop (control another PC, or let someone control this
  # one). Not wrapped: ID, password and settings are its own state, in
  # ~/.config/rustdesk. Connections go through RustDesk's public relay
  # servers, so no firewall ports need opening. (Only "direct IP access" in
  # its settings would need TCP 21118 open.)
  flake.nixosModules.rustdesk = {pkgs, ...}: {
    environment.systemPackages = [pkgs.rustdesk];
  };
}
