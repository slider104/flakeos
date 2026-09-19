{
  # Run downloaded (non-Nix) binaries.
  #
  # Programs built for ordinary distros have their loader hardcoded to
  # /lib64/ld-linux-x86-64.so.2, which on NixOS is only a stub that prints
  # "cannot run dynamically linked executables". nix-ld puts a real shim
  # there, so a binary you downloaded just runs: AppImages, itch.io/GOG
  # games, VS Code extensions, npm/pip native modules, vendor SDKs.
  #
  # The libraries below are a single system-wide fallback pool, not a list
  # per program. They are appended to LD_LIBRARY_PATH, so a program's own
  # bundled libraries still win.
  #
  # Two things nix-ld deliberately does not do: it gives a loader and a
  # library path, not a filesystem, so a program that wants /usr/bin/... or
  # /usr/share/... still needs `steam-run ./thatprogram` (from programs/steam).
  # And it only covers 64-bit; old 32-bit games also want steam-run.
  flake.nixosModules.nix-ld = {pkgs, ...}: {
    programs.nix-ld.enable = true;

    # Added to the module's own defaults (zlib, openssl, curl, systemd, ...),
    # not replacing them: NixOS merges list options by concatenation.
    programs.nix-ld.libraries = with pkgs; [
      # Graphics. vulkan-loader is what finds the actual driver.
      vulkan-loader
      libGL
      libglvnd
      libdrm

      # Windowing. Toolkits like glfw and SDL dlopen these by name at
      # startup, so they have to be findable even for a Wayland-only session.
      wayland
      libxkbcommon
      libx11
      libxcursor
      libxi
      libxrandr
      libxinerama
      libxext
      libxrender
      libxfixes
      libxcb

      # Sound. Most engines talk ALSA or PulseAudio; PipeWire answers both.
      alsa-lib
      libpulseaudio

      # Text and fonts.
      fontconfig
      freetype

      # .NET and other managed runtimes want ICU for dates and sorting,
      # and libunwind for stack traces.
      icu
      libunwind

      # Electron and Chromium-based apps (VS Code, many AppImages).
      glib
      dbus
      expat
      nss
      nspr
      at-spi2-core
      cups
      gtk3
      pango
      cairo
      gdk-pixbuf
      libxcomposite
      libxdamage
      libxtst
      libxscrnsaver
    ];
  };
}
