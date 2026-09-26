{
  # Brave. A second browser, for the sites Firefox can't do at all: the ones
  # that talk to hardware over WebHID/WebUSB/WebSerial. Firefox has none of
  # those APIs and Mozilla won't add them, so there is no setting that fixes
  # it. The be quiet! fan controller (iocenter.bequiet.com) is why it's here.
  #
  # Configured through "policies", the same idea as our Firefox: JSON files
  # under /etc/brave/policies that Brave reads at start. Ones in managed/ are
  # locked (the settings page greys them out and says "managed"); ones in
  # recommended/ are only the default and you can still change them.
  # Your profile (bookmarks, logins, tabs) stays in
  # ~/.config/BraveSoftware/Brave-Browser.
  # Chromium's policies: https://chromeenterprise.google/policies/
  # Brave's own on top:  https://support.brave.com/hc/en-us/articles/360039248271
  # `brave://policy` shows which ones actually arrived.
  flake.nixosModules.brave = {pkgs, ...}: {
    # Firefox stays the browser for links, HTML and PDFs, so nothing here
    # touches xdg.mime (firefox.nix owns that). Brave is started by name from
    # the launcher, for the one or two sites that need it.
    environment.systemPackages = [pkgs.brave];

    # No dark-theme policy needed: Brave's theme is "system", and theme.nix
    # already sets GTK to dark and dconf's color-scheme to prefer-dark. That
    # gives both the dark browser UI and a dark `prefers-color-scheme` for
    # websites - the two things firefox.nix has to set by hand.
    # Wayland comes from NIXOS_OZONE_WL, set once in niri.nix.

    # programs.chromium only writes policy files - it installs no browser.
    # It writes them for chromium and google-chrome as well, which we don't
    # have; those files just sit there unread.
    programs.chromium = {
      enable = true;

      # Extensions, installed and kept up to date automatically. The key is
      # the extension's ID, the long word in its Chrome Web Store URL. Brave
      # serves the store through its own proxy, so no install URL is needed.
      extensions = [
        # Dark Reader: makes sites without a dark mode dark too.
        # Its own settings (per-site toggles etc.) live in your profile.
        "eimadpbcbfnmbkopoojfekhnkhdbieeh"
      ];

      # Locked settings.
      extraOpts = {
        # No ads. The page-level blocking is Brave Shields, which is on by
        # default at its standard setting - so deliberately nothing set for
        # it here, and no ad blocker extension next to it. What's left are
        # Brave's *own* ads, and they all hang off Rewards: the sponsored
        # wallpapers on the new tab page and the "earn BAT" notifications.
        # Rewards off takes them with it.
        BraveRewardsDisabled = true;
        # Brave News: the feed under the new tab page, sponsored cards and
        # all. This is the FirefoxHome stories feed, by another name.
        BraveNewsDisabled = true;
        # The crypto wallet, and the VPN they sell (toolbar + settings).
        BraveWalletDisabled = true;
        BraveVPNDisabled = true;
        # Brave Talk: the video-call tile on the new tab page.
        BraveTalkDisabled = true;

        # Leo, Brave's AI, is left alone on purpose - the switch for it
        # (BraveAIChatEnabled) stays yours, in the settings.

        # Telemetry, the lot: Chromium's own metrics, Brave's P3A
        # ("privacy-preserving" analytics), the daily "still in use" ping,
        # and Web Discovery, which sends pages you visit to Brave to build
        # their search index. Firefox's DisableTelemetry in four policies.
        MetricsReportingEnabled = false;
        BraveP3AEnabled = false;
        BraveStatsPingEnabled = false;
        BraveWebDiscoveryEnabled = false;

        # Account, sync, offers to save passwords.
        BrowserSignin = 0; # 0 = signing in is disabled
        SyncDisabled = true;
        PasswordManagerEnabled = true;

        # Never ask to become the default browser. Firefox is.
        DefaultBrowserSettingEnabled = false;

        # Start with the windows and tabs from last time.
        RestoreOnStartup = 1; # 1 = restore the last session

        # The be quiet! fan controller. iocenter.bequiet.com reaches it with
        # WebHID; this hands the device over without the "choose a device"
        # dialog every time. 14143 is 0x373f, be quiet!'s USB vendor ID;
        # there's no product_id, so every device of theirs matches. The udev
        # rule below is the other half of it - without that, the device node
        # is root-only and the dialog is empty anyway.
        WebHidAllowDevicesForUrls = [
          {
            devices = [{vendor_id = 14143;}];
            urls = ["https://iocenter.bequiet.com"];
          }
        ];
      };
    };

    # /dev/hidraw* belongs to root, so no browser can open it. uaccess hands
    # the be quiet! controller to whoever is logged in at the screen. Same
    # shape as the Mystic Light rule in openrgb.nix.
    services.udev.extraRules = ''
      SUBSYSTEM=="hidraw", ATTRS{idVendor}=="373f", TAG+="uaccess"
    '';
  };
}
