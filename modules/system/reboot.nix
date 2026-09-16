{
  flake.nixosModules.reboot = {pkgs, ...}: {
    # --- keyboard ---
    # USB keyboards sometimes stay dark after a reboot (their chip gets stuck
    # while the ports keep power). Fix: disconnect all USB keyboards in software
    # at the very end of every shutdown/reboot, so they start clean.
    #
    # Debug:
    #   ls -l /etc/systemd/system-shutdown/                            # hook installed?
    #   journalctl -k -b | grep -E "error -32|unable to enumerate"     # keyboard failed this boot?
    systemd.shutdown.keyboard = pkgs.writeShellScript "reboot-keyboard" ''
      for part in /sys/bus/usb/devices/*:*; do
        # class 03 = HID (input device), protocol 01 = keyboard.
        # 2>/dev/null: parts of an already disconnected device are gone.
        { read -r class < "$part/bInterfaceClass" &&
          read -r protocol < "$part/bInterfaceProtocol"; } 2>/dev/null || continue
        [ "$class" = 03 ] && [ "$protocol" = 01 ] || continue
        # "8-3.2:1.0" is a part of the device "8-3.2".
        echo 0 > "''${part%:*}/authorized" 2>/dev/null
      done
    '';
  };
}
