{
  flake.nixosModules.audio = {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true; # older 32-bit games
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };
}
