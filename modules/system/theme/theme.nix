{config, ...}: let
  theme = config.theme;
in {
  # System-wide dark theme for toolkits: GTK 3/4, Qt, cursor, icons and the TTY.
  # GTK and Qt use standard dark Adwaita; cursor, icons, fonts and the TTY come
  # from the palette. Wrapped programs (alacritty, niri, noctalia, ...) read
  # the palette themselves.
  flake.nixosModules.theme = {
    pkgs,
    lib,
    ...
  }: let
    # Standard adw-gtk3-dark: the GTK 3 port of GNOME's dark Adwaita look.
    # (It doesn't use the palette; GTK apps get Adwaita's own dark greys.)
    gtkThemeName = "adw-gtk3-dark";

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
      pkgs.adw-gtk3
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
