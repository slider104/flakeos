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
  };

  flake.nixosModules.stable = {
    nixpkgs.overlays = [self.overlays.stable];
  };
}
