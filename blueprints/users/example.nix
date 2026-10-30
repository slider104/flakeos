{
  # BLUEPRINT: a person with a login.
  # How to use it: wiki/blueprints.md
  # A host gets this user by listing `example` in its modules.
  # Real one in this repo: users/slider.nix.
  flake.nixosModules.example = {config, ...}: {
    users.users.example = {
      isNormalUser = true;
      description = "Example Person";
      extraGroups = [
        "audio"
        "gamemode"
        "input"
        "networkmanager"
        "video"
        # "wheel"          # uncomment to allow sudo
      ];
      shell = config.programs.zsh.package; # the wrapped zsh

      # Only used when the account is first created. Change it with `passwd`.
      initialPassword = "example";
    };
  };
}
