{
  # BLUEPRINT: a program that is NOT wrapped. For programs that keep their own
  # settings (Steam, launchers, GUI apps with a settings dialog) or need nothing.
  # Copy this folder to modules/programs/<name>/ and replace every `example`.
  # Real examples in this repo: programs/steam/, programs/lutris/.
  flake.nixosModules.example = {
    pkgs,
    lib,
    ...
  }: {
    # Does NixOS have a module for it? Search "example" on
    #   https://search.nixos.org/options
    # If yes, use it (it often sets up extra things like services, groups, firewall):
    programs.example.enable = true;

    # If not, just install the package (search on https://search.nixos.org/packages):
    # environment.systemPackages = [pkgs.example];

    # Optional: make it the default app for some file types
    # (the name is its .desktop file, see /run/current-system/sw/share/applications/).
    xdg.mime.defaultApplications = lib.genAttrs [
      "application/x-example"
    ] (_: "example.desktop");
  };
}
