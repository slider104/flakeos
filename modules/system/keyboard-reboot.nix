{
  flake.nixosModules.keyboard-reboot = {pkgs, ...}: {
    # Some USB keyboards sometimes stay dark after a reboot, not after a
    # shutdown. On a reboot the USB ports keep their power, so the keyboard's
    # own chip never restarts, and it can be left stuck: the kernel log of the
    # next boot shows "device descriptor read/64, error -32" and then
    # "unable to enumerate USB device". Unplug/replug or a shutdown fixes it.
    #
    # Workaround: at the very end of every shutdown/reboot (after all programs
    # are stopped, right before the machine restarts), cleanly disconnect all
    # USB keyboards in software, so they start the next boot from a clean
    # state. "Keyboard" means any USB device that says it has a keyboard part;
    # that includes some mice with macro buttons, which is harmless.
    #
    # systemd runs everything in /etc/systemd/system-shutdown at that moment.
    systemd.shutdown.keyboard-reboot = pkgs.writeShellScript "keyboard-reboot" ''
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
