{
  # Prism Launcher (Minecraft). Not wrapped: accounts, instances and its own
  # settings are runtime state, stored in ~/.local/share/PrismLauncher.
  # It ships the Java versions Minecraft needs.
  flake.nixosModules.prismlauncher = {pkgs, ...}: {
    environment.systemPackages = [pkgs.prismlauncher];
  };
}
