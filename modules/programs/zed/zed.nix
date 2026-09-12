{config, ...}: let
  theme = config.theme;
  wrappers = config.flake.wrappers;

  # A Zed theme built from the palette, so Zed matches the Adwaita-dark look
  # of everything else. Keys Zed knows but we don't set fall back to Zed's
  # default dark theme. Theme reference: https://zed.dev/docs/extensions/themes
  a = color: alpha: color + alpha; # "#3584e4" + "33" -> "#3584e433" (hex alpha)
  status = name: color: {
    ${name} = color;
    "${name}.background" = a color "1a";
    "${name}.border" = color;
  };
  syntax = color: {inherit color;};

  zedTheme = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "Palette";
    author = "flakeos";
    themes = [
      {
        name = "Adwaita Dark (palette)";
        appearance = "dark";
        style =
          {
            # Surfaces: editor = bg, everything around it = surface.
            background = theme.surface;
            "surface.background" = theme.surface;
            "elevated_surface.background" = theme.surface;
            "panel.background" = theme.surface;
            "panel.focused_border" = theme.accent;
            "title_bar.background" = theme.surface;
            "title_bar.inactive_background" = theme.surface;
            "status_bar.background" = theme.surface;
            "toolbar.background" = theme.bg;
            "tab_bar.background" = theme.surface;
            "tab.inactive_background" = theme.surface;
            "tab.active_background" = theme.bg;

            "editor.background" = theme.bg;
            "editor.foreground" = theme.text;
            "editor.gutter.background" = theme.bg;
            "editor.subheader.background" = theme.surface;
            # A faint tint of the text colour, like Adwaita's own hover effect.
            "editor.active_line.background" = a theme.text "0d";
            "editor.highlighted_line.background" = a theme.text "0d";
            "editor.line_number" = theme.bright.black;
            "editor.active_line_number" = theme.text;
            "editor.hover_line_number" = theme.muted;
            "editor.invisible" = theme.border;
            "editor.wrap_guide" = theme.overlay;
            "editor.active_wrap_guide" = theme.border;
            "editor.document_highlight.read_background" = a theme.accent "1a";
            "editor.document_highlight.write_background" = a theme.accent "33";

            "border" = theme.border;
            "border.variant" = theme.overlay;
            "border.focused" = theme.accent;
            "border.selected" = theme.accent;
            "border.transparent" = "#00000000";
            "border.disabled" = theme.overlay;

            "element.background" = theme.overlay;
            "element.hover" = theme.overlay;
            "element.active" = theme.border;
            "element.selected" = theme.border;
            "element.disabled" = theme.surface;
            "ghost_element.background" = "#00000000";
            "ghost_element.hover" = theme.overlay;
            "ghost_element.active" = theme.border;
            "ghost_element.selected" = theme.border;
            "ghost_element.disabled" = "#00000000";
            "drop_target.background" = a theme.accent "33";

            "text" = theme.text;
            "text.muted" = theme.muted;
            "text.placeholder" = theme.bright.black;
            "text.disabled" = theme.bright.black;
            "text.accent" = theme.accent;
            "icon" = theme.text;
            "icon.muted" = theme.muted;
            "icon.disabled" = theme.bright.black;
            "icon.placeholder" = theme.muted;
            "icon.accent" = theme.accent;
            "link_text.hover" = theme.accent;

            "scrollbar.thumb.background" = a theme.border "99";
            "scrollbar.thumb.hover_background" = theme.border;
            "scrollbar.thumb.border" = "#00000000";
            "scrollbar.track.background" = "#00000000";
            "scrollbar.track.border" = "#00000000";

            "search.match_background" = a theme.accent "40";
            "search.active_match_background" = a theme.accent "80";

            "version_control.added" = theme.bright.green;
            "version_control.modified" = theme.bright.yellow;
            "version_control.deleted" = theme.bright.red;

            # Zed's built-in terminal.
            "terminal.background" = theme.bg;
            "terminal.foreground" = theme.text;
            "terminal.bright_foreground" = theme.bright.white;
            "terminal.dim_foreground" = theme.muted;

            players = [
              {
                cursor = theme.accent;
                background = theme.accent;
                selection = a theme.accent "3d";
              }
            ];

            syntax = {
              comment = syntax theme.muted;
              "comment.doc" = syntax theme.muted;
              keyword = syntax theme.bright.magenta;
              preproc = syntax theme.bright.magenta;
              function = syntax theme.bright.blue;
              constructor = syntax theme.bright.blue;
              type = syntax theme.bright.yellow;
              enum = syntax theme.bright.yellow;
              namespace = syntax theme.bright.yellow;
              string = syntax theme.bright.green;
              "string.escape" = syntax theme.bright.cyan;
              "string.regex" = syntax theme.bright.cyan;
              "string.special" = syntax theme.bright.cyan;
              "string.special.symbol" = syntax theme.bright.cyan;
              number = syntax theme.bright.red;
              boolean = syntax theme.bright.red;
              constant = syntax theme.bright.red;
              property = syntax theme.bright.cyan;
              attribute = syntax theme.bright.cyan;
              label = syntax theme.bright.cyan;
              tag = syntax theme.bright.red;
              variable = syntax theme.text;
              "variable.parameter" = syntax theme.text;
              "variable.special" = syntax theme.bright.red;
              operator = syntax theme.bright.cyan;
              punctuation = syntax theme.muted;
              "punctuation.bracket" = syntax theme.muted;
              "punctuation.delimiter" = syntax theme.muted;
              "punctuation.special" = syntax theme.bright.magenta;
              title = syntax theme.accent // {font_weight = 700;};
              "link_text" = syntax theme.bright.blue;
              "link_uri" = syntax theme.bright.cyan;
              emphasis = {font_style = "italic";};
              "emphasis.strong" = {font_weight = 700;};
            };
          }
          # error / warning / ... each with a matching background + border.
          // status "error" theme.error
          // status "warning" theme.bright.yellow
          // status "success" theme.bright.green
          // status "info" theme.accent
          // status "hint" theme.muted
          // status "created" theme.bright.green
          // status "modified" theme.bright.yellow
          // status "deleted" theme.bright.red
          // status "conflict" theme.bright.yellow
          // status "renamed" theme.accent
          // status "ignored" theme.bright.black
          // status "hidden" theme.bright.black
          // status "unreachable" theme.muted
          // status "predictive" theme.bright.black
          # The 16 terminal colours.
          // builtins.listToAttrs (builtins.concatLists (map (n: [
            {
              name = "terminal.ansi.${n}";
              value = theme.normal.${n};
            }
            {
              name = "terminal.ansi.bright_${n}";
              value = theme.bright.${n};
            }
            {
              name = "terminal.ansi.dim_${n}";
              value = theme.normal.${n};
            }
          ]) ["black" "red" "green" "yellow" "blue" "magenta" "cyan" "white"]));
      }
    ];
  };
in {
  # Zed. It can't be pointed at a config file: it always reads
  # ~/.config/zed/, and writes its own settings.json there. So the wrapper
  # runs a small step before every start that links two files in:
  #
  #   ~/.config/zed/global_settings.json -> settings.json next to this file
  #   ~/.config/zed/themes/palette.json  -> theme generated from the palette
  #
  # Zed layers them: its defaults < global_settings.json (ours) < settings.json
  # (yours, written by Zed's UI). So Zed starts in "Adwaita Dark (palette)",
  # and changes you make in Zed still work and are saved.
  flake.wrappers.zed-editor = {
    wlib,
    pkgs,
    ...
  }: let
    themeFile = pkgs.writeText "zed-palette-theme.json" (builtins.toJSON zedTheme);

    linkConfig = pkgs.writeShellScript "zed-link-config" ''
      cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/zed"
      mkdir -p "$cfg/themes"
      ln -sfn ${./settings.json} "$cfg/global_settings.json"
      ln -sfn ${themeFile} "$cfg/themes/palette.json"
    '';
  in {
    imports = [wlib.modules.default];
    package = pkgs.zed-editor;
    runShell = ["${linkConfig}"];
    aliases = ["zed"]; # `zed .` works too, not just `zeditor .`
  };

  flake.nixosModules.zed = {
    imports = [wrappers.zed-editor.install];
    wrappers.zed-editor.enable = true;
  };
}
