{
  # BLUEPRINT: a person with a login.
  # Copy to modules/users/<name>.nix and replace every `example`.
  # Then add `example` to the modules list of each host they should exist on.
  # Real example in this repo: users/slider.nix.
  flake.nixosModules.example = {config, ...}: {
    users.users.example = {
      isNormalUser = true;
      description = "Example Person";
      extraGroups = [
        # "wheel"          # uncomment to allow sudo
        "networkmanager"
        "video"
        "audio"
        "input"
        "gamemode"
      ];
      shell = config.programs.zsh.package; # the wrapped zsh

      # Only used when the account is first created. Change it with `passwd`.
      initialPassword = "example";
    };
  };
}
