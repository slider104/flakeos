{
  # Fresh: a terminal text editor (`fresh <file>`), with mouse support, menus
  # and language servers. Not wrapped: its settings are yours, in
  # ~/.config/fresh/config.json, written by its own settings menu.
  # The nixpkgs package already starts it with --no-upgrade-check (no "new
  # version" check, no anonymous telemetry); updates come from nixpkgs (`nup`).
  #
  # For Nix files it starts `nil` (installed by programs/nix-tools) when you
  # enable the language server in its menu.
  flake.nixosModules.fresh = {pkgs, ...}: {
    environment.systemPackages = [pkgs.fresh-editor];
  };
}
