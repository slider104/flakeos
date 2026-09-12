{
  # User "slider". A host gets this user by importing `self.nixosModules.slider`.
  # To add another person: copy this file, rename, import it in the host.
  flake.nixosModules.slider = {config, ...}: {
    users.users.slider = {
      isNormalUser = true;
      description = "slider";
      extraGroups = [
        "wheel" # sudo
        "networkmanager"
        "video"
        "audio"
        "input"
        "gamemode" # lets gamemode tune CPU/GPU without a password prompt (ignored if gaming isn't installed)
      ];
      shell = config.programs.zsh.package; # the wrapped zsh (programs/zsh)

      # Only used when the user is first created. Change it right after the
      # first login with `passwd`; NixOS keeps the new one from then on.
      initialPassword = "slider";
    };
  };
}
