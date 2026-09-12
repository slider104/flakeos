{
  # LibreOffice: Writer, Calc, Impress, Draw (documents, spreadsheets,
  # presentations). Not wrapped: it keeps its settings itself
  # (~/.config/libreoffice). It uses the GTK theme, so it's dark like the rest.
  # It registers itself for .odt/.docx/.xlsx/.pptx etc.; PDFs still open in
  # Firefox (set in firefox.nix).
  flake.nixosModules.libreoffice = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      libreoffice
      # Spell check dictionaries. LibreOffice finds them in the system
      # profile (/run/current-system/sw/share/hunspell). Pick the language
      # per document: Tools → Language.
      hunspellDicts.de_DE
      hunspellDicts.en_US
    ];
  };
}
