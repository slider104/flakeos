{
  # --- keyboard dead after a reboot ---
  #
  # The keyboard hangs off the Genesys hub on
  # port "8-3-port2". On a warm reboot the board keeps 5V on that port, so the
  # keyboard's own chip never restarts. It comes back up in a confused state
  # and the kernel cannot talk to it:
  #
  #   usb 8-3.2: device descriptor read/64, error -32
  #   usb 8-3.2: device not accepting address 9, error -71
  #   usb 8-3-port2: unable to enumerate USB device
  #
  # A real power-off fixes it because the port loses power for a moment.
  # Unplugging and plugging the keyboard back in does the same thing.
  #
  # So we cut the power. A USB hub can switch each of its ports off,
  # and the kernel exposes that as the port's "disable" file:
  #
  #   echo 1 > .../8-3-port2/disable     power off
  #   echo 0 > .../8-3-port2/disable     power on again
  #
  # Two places use it:
  #   1. a shutdown hook - power off every keyboard port on the way down, so
  #      the keyboard starts from scratch on the next boot.
  #   2. a rescue service - if a device still failed to come up, power-cycle
  #      exactly the ports the kernel complained about.
  #
  # Debug:
  #   ls -l /etc/systemd/system-shutdown/                       # hook installed?
  #   journalctl -k -b | grep "unable to enumerate"             # a port failed this boot?
  #   systemctl status usb-rescue                               # did the rescue run?
  flake.nixosModules.reboot = {pkgs, ...}: {
    # 1. On the way down: switch off every port that has a keyboard on it.
    #
    # Ports live next to their hub in /sys, e.g.
    #   /sys/bus/usb/devices/8-3:1.0/8-3-port2
    # and each port has a "device" link to whatever is plugged into it.
    systemd.shutdown.keyboard = pkgs.writeShellScript "reboot-keyboard" ''
      for port in /sys/bus/usb/devices/*:1.0/*-port*; do
        [ -w "$port/disable" ] || continue        # hub cannot switch this port
        [ -e "$port/device" ] || continue         # nothing plugged in

        # A device shows what it is per interface: class 03 = HID (input
        # device), protocol 01 = keyboard. 2>/dev/null: some interfaces have
        # no such file.
        #
        # This also catches the mouse, which carries a keyboard
        # interface for its macro keys. Switching it off for a moment on the
        # way down does no harm.
        for iface in "$port"/device/*:*; do
          { read -r class < "$iface/bInterfaceClass" &&
            read -r protocol < "$iface/bInterfaceProtocol"; } 2>/dev/null || continue
          [ "$class" = 03 ] && [ "$protocol" = 01 ] || continue
          echo 1 > "$port/disable" 2>/dev/null
          break
        done
      done
    '';

    # 2. After boot: repair ports that came up empty anyway.
    #
    # The kernel prints one line per port it gave up on, e.g.
    #   usb 8-3-port2: unable to enumerate USB device
    # We read those lines back out of this boot's kernel log and switch each
    # of those ports off and on again, which is the software version of
    # unplugging the device. Nothing else is touched.
    systemd.services.usb-rescue = {
      description = "Power-cycle USB ports whose device failed to start";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [pkgs.systemd pkgs.gnused pkgs.coreutils];
      script = ''
        # Give the kernel time to finish its own retries (it tries for ~5s).
        sleep 5

        ports=$(journalctl -k -b --no-pager |
          sed -n 's/.*usb \([^ :]*-port[0-9]*\): unable to enumerate USB device.*/\1/p' |
          sort -u)

        [ -n "$ports" ] || exit 0

        for name in $ports; do
          for port in /sys/bus/usb/devices/*:1.0/"$name"; do
            [ -w "$port/disable" ] || continue
            echo "power-cycling $name"
            echo 1 > "$port/disable"
            sleep 2
            echo 0 > "$port/disable"
          done
        done
      '';
    };
  };
}
