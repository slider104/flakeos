{
  # BLUEPRINT: a person with a login.
  # How to use it: blueprints/README.md
  # A host gets this user by listing `example` in its modules.
  # Real one in this repo: users/slider.nix.
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
