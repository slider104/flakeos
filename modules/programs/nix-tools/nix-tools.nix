{
  # Tools for editing Nix files (this repo). Editors find them on the PATH.
  #
  #   nixd       language server: completion, errors while you type, and docs
  #              on hover. Knows every NixOS option of this flake (see the
  #              "lsp" section in programs/zed/settings.json). Used by Zed.
  #   nil        a lighter language server (knows the Nix language, not the
  #              options). Fresh's default for Nix files.
  #   alejandra  the formatter. The same one `nix fmt` uses, so formatting on
  #              save in Zed gives exactly what `nix fmt .` gives.
  flake.nixosModules.nix-tools = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      nixd
      nil
      alejandra
    ];
  };
}
