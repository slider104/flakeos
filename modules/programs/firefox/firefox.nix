{
  # Firefox. Configured through "policies": NixOS builds a wrapped Firefox with
  # these baked in. It's the same idea as our wrappers, done by nixpkgs itself.
  # Your profile (bookmarks, logins, tabs) stays in ~/.mozilla.
  # All policies: https://mozilla.github.io/policy-templates/
  flake.nixosModules.firefox = {lib, ...}: {
    # Links and web pages open in Firefox. PDFs too (built-in viewer).
    xdg.mime.defaultApplications = lib.genAttrs [
      "text/html"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "application/pdf"
    ] (_: "firefox.desktop");

    programs.firefox = {
      enable = true;
      policies = {
        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DontCheckDefaultBrowser = true;
        OfferToSaveLogins = false;

        # Start with the windows and tabs from last time.
        Homepage.StartPage = "previous-session";

        # New tab page: the search box and your own most-visited sites, nothing
        # else. Off go the sponsored shortcuts (the tiles marked "Sponsored"),
        # the recommended-stories feed below them and the snippets. Locked, so
        # the gear menu on the new tab page can't switch them back on.
        FirefoxHome = {
          Search = true;
          TopSites = true;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };

        # Extensions, installed and kept up to date automatically. The key is
        # the extension's ID; the URL's slug is its addons.mozilla.org name.
        ExtensionSettings = {
          # uBlock Origin: ad and tracker blocker.
          "uBlock0@raymondhill.net" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          };
          # Dark Reader: makes sites without a dark mode dark too.
          # Its own settings (per-site toggles etc.) live in your profile.
          "addon@darkreader.org" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          };
        };

        # Dark browser UI and dark websites (where the site supports it).
        Preferences = {
          "extensions.activeThemeID" = {
            Value = "firefox-compact-dark@mozilla.org";
            Status = "default";
          };
          "layout.css.prefers-color-scheme.content-override" = {
            Value = 0; # 0 = dark
            Status = "default";
          };
          # Never translate pages on its own: German sites stay German, English
          # stay English. Translating by hand (icon in the address bar) still
          # works. Locked, so an old "always translate" choice can't win.
          "browser.translations.automaticallyPopup" = {
            Value = false;
            Status = "locked";
          };
          "browser.translations.alwaysTranslateLanguages" = {
            Value = "";
            Status = "locked";
          };
          # The weather box on the new tab page. FirefoxHome above has no
          # switch for it, so it goes off here.
          "browser.newtabpage.activity-stream.showWeather" = {
            Value = false;
            Status = "locked";
          };
          # Belt and braces for the stories feed: recent Firefox serves it
          # through the "discovery stream", which ignores the Pocket policy.
          "browser.newtabpage.activity-stream.feeds.section.topstories" = {
            Value = false;
            Status = "locked";
          };
          "browser.newtabpage.activity-stream.discoverystream.enabled" = {
            Value = false;
            Status = "locked";
          };
        };
      };
    };
  };
}
