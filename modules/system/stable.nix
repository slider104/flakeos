{
  self,
  inputs,
  ...
}: {
  # An escape hatch for broken packages.
  #
  # The system follows nixpkgs-unstable, so now and then a package there does
  # not build. On 2026-10-04 that was `breakpad` (it failed to link against
  # the new gcc), and because noctalia depends on it, the whole system could
  # not be built. The only ways out were to freeze everything by reverting
  # flake.lock, or to carry a patch of our own. This is a third one: take the
  # broken package from the stable release instead and let the rest of the
  # system move on. `flake.nix` holds the second nixpkgs it comes from.
  #
  # Two ways to use it:
  #
  #   1. One program from stable, nothing else touched. `pkgs.stable` is the
  #      whole stable package set and can be used in any module, exactly like
  #      `pkgs`:
  #        environment.systemPackages = [pkgs.stable.inkscape];
  #
  #   2. One package replaced *everywhere*, including inside other packages
  #      that depend on it - what the breakpad case needed, since the broken
  #      package was a dependency of noctalia, not something we install
  #      ourselves. Uncomment a line in the list at the bottom.
  #
  # Why this is an overlay: an overlay changes `pkgs` itself, before any
  # module reads a package out of it. So the replacement reaches every way of
  # asking for that package - `with pkgs; [...]`, `pkgs.foo`, `package =
  # pkgs.foo` - without a single one of those lines needing to change. It
  # reaches the wrapped programs too: a wrapper is handed the pkgs of the
  # system it is installed into (nix-wrapper-modules' `.install`), so it is
  # the same, already-patched `pkgs`. And `setup/parts.nix` builds the
  # flake's own packages (`nix build .#<prog>`) from a pkgs with this overlay
  # as well, so a package you build by hand matches the one the system gets.
  #
  # The cost: a package from stable brings stable's own dependencies with it
  # (its glibc, its Qt), so a big program can mean downloading a second copy
  # of a library stack. That is the price of not freezing everything, and it
  # disappears again when the line goes away. Which it should: these lines
  # are meant to be deleted once unstable is fixed, so always leave a note
  # saying what broke.
  flake.overlays.stable = final: prev: {
    # Nothing here is evaluated - and the stable nixpkgs is not even imported
    # - until something actually asks for `pkgs.stable.<something>`.
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      # Follow the one nixpkgs setting this config changes (system/nix.nix),
      # so an unfree package works here too. The whole `prev.config` cannot
      # be handed over: by then it is nixpkgs own evaluated settings, not the
      # ones you write.
      config.allowUnfree = prev.config.allowUnfree;
    };

    # --- replacements: uncomment a line when a package on unstable is broken
    #
    # breakpad = final.stable.breakpad; # 2026-10-04: vtable link error, nixpkgs#569271

    # 2026-10-25: nixpkgs *removed* `noctalia-shell`. Unstable now ships
    # `noctalia` 5.x instead, which is not a new version but a rewrite: C++
    # and meson rather than QuickShell and QML, the binary is called
    # `noctalia`, its config is one TOML file (~/.config/noctalia/config.toml,
    # found via NOCTALIA_CONFIG_HOME) instead of settings.json + colors.json,
    # and keybinds call `noctalia msg ...` instead of
    # `noctalia-shell ipc call ...`. nix-wrapper-modules has no module for it
    # yet, so programs/noctalia/noctalia.nix cannot simply point at the new
    # package - that is a migration, not an edit.
    #
    # So this line is different from the breakpad one above. That package was
    # temporarily broken and the line could be deleted once unstable caught
    # up. This one never will be: 4.x is gone and unmaintained. It holds the
    # bar exactly as it is today and lets the rest of the system keep
    # updating, until the migration to 5.x is done - then delete this line
    # *and* rewrite the noctalia module in the same step.
    #
    # This one also has to come from a *recent* commit, not the stable
    # release, and that is why nixpkgs-stable points at a pinned unstable
    # revision (see flake.nix). Taken from the release branch, noctalia
    # starts, answers ipc and finds its wallpapers, but draws nothing at all:
    # no bar, no wallpaper, no dock. Its QuickShell then logs
    #
    #   qt.qpa.wayland: EGL not available
    #   Failed to create graphics context for ...WlrLayershell
    #
    # A borrowed package brings its own glibc, but not its own graphics
    # driver: Mesa is dlopen'ed from /run/opengl-driver, which belongs to the
    # system's nixpkgs, into the borrowed package's process. Unstable's Mesa
    # needs GLIBC_2.44; the release branch was still on glibc 2.42, so the
    # driver could not resolve its symbols, EGL stayed unavailable, and every
    # layer-shell surface failed to get a context. Everything that is plain
    # QML kept working, which is why it looked alive but invisible.
    #
    # The pin is 4.7.7, one patch newer than the release branch's 4.7.6, and
    # shares its glibc, Qt and Mesa with the system instead of adding a
    # second copy of that stack (~400 store paths).
    #
    # Note the pin is only safe while the system's Mesa needs nothing newer
    # than the pin's glibc provides. The next glibc bump on unstable will
    # break it again in exactly the same way - the fix then is to move the
    # pin forward, or finally do the 5.x migration.
    noctalia-shell = final.stable.noctalia-shell;
  };

  flake.nixosModules.stable = {
    nixpkgs.overlays = [self.overlays.stable];
  };
}
