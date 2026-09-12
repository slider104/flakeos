{config, ...}: let
  theme = config.theme;
in {
  # System-wide dark theme for toolkits: GTK 3/4, Qt, cursor, icons and the TTY.
  # Wrapped programs (alacritty, niri, noctalia, ...) read the palette themselves.
  flake.nixosModules.theme = {
    pkgs,
    lib,
    ...
  }: let
    gtkThemeName = "flakeos-dark";

    # Our GTK theme = adw-gtk3-dark with the palette appended. In GTK CSS the
    # last `@define-color` of a name wins, so this repaints the whole theme.
    paletteCss = pkgs.writeText "flakeos-palette.css" ''
      /* flakeos palette (modules/system/theme/palette.nix) */
      @define-color accent_color ${theme.accent};
      @define-color accent_bg_color ${theme.accent};
      @define-color accent_fg_color ${theme.onAccent};
      @define-color window_bg_color ${theme.bg};
      @define-color window_fg_color ${theme.text};
      @define-color view_bg_color ${theme.bg};
      @define-color view_fg_color ${theme.text};
      @define-color headerbar_bg_color ${theme.surface};
      @define-color headerbar_fg_color ${theme.text};
      @define-color headerbar_backdrop_color ${theme.bg};
      @define-color sidebar_bg_color ${theme.surface};
      @define-color sidebar_fg_color ${theme.text};
      @define-color sidebar_backdrop_color ${theme.surface};
      @define-color secondary_sidebar_bg_color ${theme.surface};
      @define-color card_bg_color ${theme.surface};
      @define-color card_fg_color ${theme.text};
      @define-color dialog_bg_color ${theme.surface};
      @define-color dialog_fg_color ${theme.text};
      @define-color popover_bg_color ${theme.surface};
      @define-color popover_fg_color ${theme.text};
      @define-color thumbnail_bg_color ${theme.overlay};
      @define-color destructive_bg_color ${theme.error};
    '';

    gtkTheme = pkgs.runCommand gtkThemeName {} ''
      mkdir -p $out/share/themes
      cp -r --no-preserve=mode ${pkgs.adw-gtk3}/share/themes/adw-gtk3-dark $out/share/themes/${gtkThemeName}
      cd $out/share/themes/${gtkThemeName}
      sed -i 's/adw-gtk3-dark/${gtkThemeName}/g' index.theme
      for css in gtk-3.0/gtk.css gtk-3.0/gtk-dark.css gtk-4.0/gtk.css gtk-4.0/gtk-dark.css; do
        cat ${paletteCss} >> "$css"
      done
    '';

    settingsIni = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=${gtkThemeName}
      gtk-icon-theme-name=${theme.icons}
      gtk-cursor-theme-name=${theme.cursor.name}
      gtk-cursor-theme-size=${toString theme.cursor.size}
      gtk-font-name=${theme.font.sans} ${toString theme.font.size}
    '';

    noHash = lib.removePrefix "#";
  in {
    environment.systemPackages = [
      gtkTheme
      pkgs.papirus-icon-theme
      pkgs.bibata-cursors
    ];

    # GTK reads these when it can't reach dconf.
    environment.etc."xdg/gtk-3.0/settings.ini".text = settingsIni;
    environment.etc."xdg/gtk-4.0/settings.ini".text = settingsIni;

    # dconf is where GTK apps and the desktop portal look first. `color-scheme`
    # is what tells Firefox, Electron and libadwaita apps "use dark".
    programs.dconf = {
      enable = true;
      profiles.user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            gtk-theme = gtkThemeName;
            icon-theme = theme.icons;
            cursor-theme = theme.cursor.name;
            cursor-size = lib.gvariant.mkInt32 theme.cursor.size;
            font-name = "${theme.font.sans} ${toString theme.font.size}";
            monospace-font-name = "${theme.font.mono} ${toString theme.font.size}";
          };
        }
      ];
    };

    # Qt apps (Prism Launcher, OpenRGB) follow GTK's dark Adwaita look.
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    environment.sessionVariables = {
      XCURSOR_THEME = theme.cursor.name;
      XCURSOR_SIZE = toString theme.cursor.size;
    };

    # The TTY (before niri starts) uses the same 16 colours.
    console.colors = map noHash (
      [theme.bg]
      ++ (with theme.normal; [red green yellow blue magenta cyan white])
      ++ (with theme.bright; [black red green yellow blue magenta cyan white])
    );
  };
}
