{
  # Steam. Not wrapped: Steam manages its own settings and library.
  # The NixOS module also sets up 32-bit graphics and controller udev rules.
  flake.nixosModules.steam = {
    config,
    pkgs,
    ...
  }: let
    # Mod+G looked like a dead keybind: niri spawned `steam`, the process
    # exited within milliseconds, nothing on screen, nothing in any log.
    #
    # Valve's launcher (bin_steam.sh, the `steam` on $PATH) starts with
    #
    #   if forward_command_line "$@"; then exit 0; fi
    #
    # and `forward_command_line` decides "Steam is already running" from one
    # thing only: can steam-runtime-steam-remote open ~/.steam/steam.pipe for
    # writing? If yes it hands the command line to whoever is on the other end
    # and exits 0 - no output at all, which is exactly what the failed presses
    # looked like. A press that works instead logs
    # "steam-runtime-steam-remote: Steam is not running: No such device or
    # address" and goes on to start the client.
    #
    # The pipe is a FIFO in $HOME, so it outlives both Steam and the reboot,
    # and that check has no way to tell a live instance from leftovers.
    # steam.sh has a correct check for the same question (is_steam_running):
    # the master process is the pid in ~/.steam/steam.pid, and it must hold
    # steam.pipe open. Run that first and clear the pipe when it says no, so
    # the launcher cannot hand the press off to a Steam that is not there.
    steam-launch = pkgs.writeShellScriptBin "steam-launch" ''
      steamdir="$HOME/.steam"
      pipe="$steamdir/steam.pipe"
      pid=$(cat "$steamdir/steam.pid" 2>/dev/null || true)

      running=
      if [ -n "$pid" ] && [ -d "/proc/$pid" ]; then
        for fd in /proc/"$pid"/fd/*; do
          if [ "$(readlink "$fd" 2>/dev/null)" = "$pipe" ]; then
            running=yes
            break
          fi
        done
      fi

      # Only ever removed when no live process holds it: a running Steam keeps
      # its pipe, so `steam-launch` still raises the window instead of starting
      # a second client.
      [ -n "$running" ] || rm -f "$pipe"

      exec ${config.programs.steam.package}/bin/steam "$@"
    '';
  in {
    programs.steam = {
      enable = true;
      # Proton-GE shows up in Steam > game > Properties > Compatibility.
      extraCompatPackages = [pkgs.proton-ge-bin];
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # What Mod+G spawns (modules/programs/niri/config.kdl).
    environment.systemPackages = [steam-launch];
  };
}
