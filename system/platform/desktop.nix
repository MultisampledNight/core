{
  config,
  pkgs,
  lib,
  ...
}@args:

with lib;
with import ../prelude args;
{
  boot.supportedFilesystems = [ "ntfs" ];

  security.rtkit.enable = true;

  networking.dhcpcd.wait = "background"; # saves like 5 seconds of startup time

  users.users = mkIf cfg.gaming {
    nichthemeron = {
      isNormalUser = true;
      extraGroups = optionals cfg.graphical [ "input" ];
      shell = pkgs.zsh;
    };
  };

  hardware.sane.enable = true;

  services = {
    udisks2.enable = true;
    printing = {
      enable = mkDefault true;
      drivers = with pkgs; [ brlaser ];
    };
    joycond.enable = true;

    tor = {
      enable = true;
      client.enable = true;
    };

    # hide the mouse cursor when not moved
    unclutter-xfixes = {
      enable = cfg.xorg;
      timeout = 8;
    };

    libinput.enable = true;
    xserver = {
      enable = cfg.xorg;

      xkb =
        let
          inNeoFamily =
            layout:
            (elem layout [
              "bone"
              "adnw"
            ])
            || (hasPrefix "neo" layout);
        in
        (
          {
            options = "";
          }
          // (
            if inNeoFamily cfg.layout then
              {
                layout = "de";
                variant = cfg.layout;
              }
            else
              {
                layout = cfg.layout;
                variant = "";
              }
          )
        );

      videoDrivers = allVideoDrivers;

      desktopManager.wallpaper = {
        mode = "fill";
        combineScreens = false;
      };
      windowManager.i3.enable = true;
    };
  };

  environment = {
    systemPackages = unite [
      (with pkgs; [
        [
          true
          [
            # system debugging tools
            clinfo
            vulkan-tools
            pciutils

            # tools
            pulseaudio-ctl
            playerctl
            vde2
            lm_sensors
          ]
        ]
        [
          cfg.graphical
          [
            # normal applications
            tor-browser-bundle-bin
            thunderbird
            xournalpp
            keepassxc
            gimp
            inkscape
            scribus
            libresprite
            libreoffice-fresh
            pavucontrol
            helvum
            mate.eom
            dunst
            qemu_kvm
            gucharmap
            evince
            kdePackages.kruler
            gnome-clocks
            d-spy
          ]
        ]
        [
          cfg.xorg
          [
            xorg.xauth
            rofi
            flameshot
          ]
        ]
        [
          cfg.multimedia
          [
            # video
            # OBS Studio and its plugins
            (wrapOBS {
              plugins = with obs-studio-plugins; [
                obs-vkcapture
                obs-pipewire-audio-capture
                input-overlay
              ];
            })
            libsForQt5.kdenlive

            # audio
            audacity
            lmms
            musescore
            vcv-rack
            polyphone
            easyeffects
          ]
        ]
      ])
      (with unstable; [
        [
          true
          [
            # zathura for viewing, evince for live-reloading
            # since zathura flickers white when reloading, but evince does so only with the background color
            zathura
            scrcpy
            element-desktop
            signal-desktop
          ]
        ]
        [
          cfg.graphical
          [ blender ]
        ]
      ])
      (with custom; [
        [
          true
          [ layaway nyandere ]
        ]
      ])
    ];

    sessionVariables = {
      BROWSER = "firefox";
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    firejail.enable = true;
    nix-ld.enable = true;

    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
      settings =
        let
          hours = n: n * 60 * 60;
        in
        {
          default-cache-ttl = hours 2;
          max-cache-ttl = hours 6;
        };
    };

    ssh = {
      startAgent = true;
      enableAskPassword = false;
      agentTimeout = "4h";
    };

    firefox = {
      enable = true;
      package = pkgs.firefox-esr;
      # https://mozilla.github.io/policy-templates/
      policies =
        let
          librsIcon = "https://lib.rs/logo.svg";
          cratesIcon = "https://crates.io/favicon.ico";
          pypiIcon = "https://pypi.org/static/images/favicon.35549fe8.ico";

          pythonIcon = "https://docs.python.org/3/_static/py.svg";
          rustIcon = "https://doc.rust-lang.org/static.files/favicon-32x32-422f7d1d52889060.png";

          docsrsIcon = "https://docs.rs/-/static/favicon.ico";

          archIcon = "https://archlinux.org/static/favicon.51c13517c44c.png";
          nixIcon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";

          ytIcon = "https://www.youtube.com/s/desktop/a258f8cf/img/favicon_32x32.png";
          typstIcon = "https://typst.app/assets/favicon-32x32.png";

          blenderIcon = "https://docs.blender.org/manual/en/latest/_static/favicon.png";
          steamdbIcon = "https://steamdb.info/static/logos/vector_prefers_schema.svg";
          wikipediaIcon = "https://en.wikipedia.org/static/favicon/wikipedia.ico";
          wikidataIcon = "https://www.wikidata.org/static/favicon/wikidata.ico";
          osmIcon = "https://www.openstreetmap.org/assets/osm_logo-4b074077c29e100f40ee64f5177886e36b570d4cc3ab10c7b263003d09642e3f.svg";
        in
        {
          DownloadDirectory = "\${home}/media/downloads";

          Cookies = {
            Behavior = "reject-foreign";
            BehaviorPrivateBrowsing = "reject";

            # surprisingly many websites just... don't work without third-party cookies
            # so yeah, here we allow them. unfortunately.
            Allow = [
              "https://www.zdf.de/"
              "https://docs.python.org/"
              "https://doc.rust-lang.org/"
              "https://www.openstreetmap.org/"
              "https://tile.openstreetmap.org/"
            ];
          };
          SanitizeOnShutdown = {
            Cache = true;
            Cookies = true;
            Downloads = false;
            FormData = true;
            History = true;
            Sessions = true;
            SiteSettings = true;
            OfflineApps = true;
            Locked = false;
          };
          EnableTrackingProtection = {
            Value = true;
            Cryptomining = true;
            Fingerprinting = true;
            EmailTracking = true;
          };
          Permissions = {
            Camera.BlockNewRequests = true;
            Microphone.BlockNewRequests = true;
            Location.BlockNewRequests = true;
            Notifications.BlockNewRequests = true;
            Autoplay.Default = "block-audio-video";
          };

          DNSOverHTTPS = {
            Enabled = true;
            Fallback = true;
          };
          NetworkPrediction = false;

          NoDefaultBookmarks = true;
          Bookmarks =
            mapAttrsToList
              (name: url: {
                Title = name;
                URL = url;
                Favicon =
                  if hasPrefix "Nix" name then
                    nixIcon
                  else if hasPrefix "Typst" name then
                    typstIcon
                  else if hasPrefix "Rust" name then
                    rustIcon
                  else
                    "";
              })
              {
                "NixOS manual" = "https://nixos.org/manual/nixos/stable/";
                "Nixpkgs manual" = "https://nixos.org/manual/nixpkgs/stable/";
                "Nix manual" = "https://nix.dev/manual/nix/rolling/";
                "Typst documentation" = "https://typst.app/docs";
                "oklch" = "https://oklch.com/";

                "Rust nomicon" = "https://doc.rust-lang.org/nomicon/";
                "Rust reference" = "https://doc.rust-lang.org/reference/";
                "Rust API guidelines" = "https://rust-lang.github.io/api-guidelines/checklist.html";
                "Rust edition guide" = "https://doc.rust-lang.org/edition-guide/";
                "Rust Cargo book" = "https://doc.rust-lang.org/cargo/";
                "Rust rustc book" = "https://doc.rust-lang.org/rustc/";
                "Rust rustdoc book" = "https://doc.rust-lang.org/rustdoc/";
                "Rust unstable book" = "https://doc.rust-lang.org/nightly/unstable-book/";
                "Rust rustup book" = "https://rust-lang.github.io/rustup/index.html";
                "Rust performance book" = "https://nnethercote.github.io/perf-book/title-page.html";

                "Julia docs" = "https://docs.julialang.org/en/v1/";
                "Julia LinearAlgebra" = "https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/";
              };

          DontCheckDefaultBrowser = true;
          PromptForDownloadLocation = false;

          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          OfferToSaveLogins = false;
          PasswordManagerEnabled = false;
          DisableFormHistory = true;

          DisableFirefoxAccounts = true;
          DisableFirefoxScreenshots = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableProfileImport = true;
          DisableTelemetry = true;

          DisableSetDesktopBackground = true;

          ShowHomeButton = false;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "never";

          SearchBar = "unified";
          SearchEngines = {
            PreventInstalls = true;

            Default = "DuckDuckGo";
            Add = [
              {
                Name = "Lib.rs";
                Description = "Static frontend to the Rust crate index";
                Alias = "@rspkgs";
                URLTemplate = "https://lib.rs/search?q={searchTerms}";
                Method = "GET";
                IconURL = librsIcon;
              }
              {
                Name = "Rust crate registry";
                Alias = "@rspkgs-slow";
                URLTemplate = "https://crates.io/search?q={searchTerms}";
                Method = "GET";
                IconURL = cratesIcon;
              }
              {
                Name = "Python package index";
                Alias = "@pypkgs";
                URLTemplate = "https://pypi.org/search/?q={searchTerms}";
                Method = "GET";
                IconURL = pypiIcon;
              }
              {
                Name = "Arch Linux packages";
                Alias = "@archpkgs";
                URLTemplate = "https://archlinux.org/packages/?q={searchTerms}";
                Method = "GET";
                IconURL = archIcon;
              }
              {
                Name = "Nix packages";
                Alias = "@nixpkgs";
                URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                Method = "GET";
                IconURL = nixIcon;
              }
              {
                Name = "Arch wiki";
                Alias = "@archdoc";
                URLTemplate = "https://wiki.archlinux.org/index.php?search={searchTerms}&title=Special%3ASearch";
                Method = "GET";
                IconURL = archIcon;
              }
              {
                Name = "Python stdlib documentation";
                Alias = "@pydoc";
                URLTemplate = "https://docs.python.org/3/search.html?q={searchTerms}";
                Method = "GET";
                IconURL = pythonIcon;
              }
              {
                Name = "Rust stdlib documentation";
                Alias = "@rsdoc";
                URLTemplate = "https://doc.rust-lang.org/std/index.html?search={searchTerms}";
                Method = "GET";
                IconURL = rustIcon;
              }
              {
                Name = "Rust crate documentation";
                Alias = "@rsext";
                URLTemplate = "https://docs.rs/releases/search?query={searchTerms}&sort=recent-downloads";
                Method = "GET";
                IconURL = docsrsIcon;
              }
              {
                Name = "NixOS options";
                Alias = "@nixopts";
                URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
                Method = "GET";
                IconURL = nixIcon;
              }
              {
                Name = "NixOS wiki";
                Alias = "@nixdoc";
                URLTemplate = "https://nixos.wiki/index.php?search={searchTerms}&go=Go";
                Method = "GET";
                IconURL = nixIcon;
              }
              {
                Name = "Typst universe";
                Alias = "@typpkgs";
                URLTemplate = "https://typst.app/universe/search?q={searchTerms}";
                Method = "GET";
                IconURL = typstIcon;
              }
              {
                Name = "YouTube";
                Alias = "@youtube";
                URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
                Method = "GET";
                IconURL = ytIcon;
              }
              {
                Name = "ZDF";
                Alias = "@zdf";
                URLTemplate = "https://www.zdf.de/suche?q={searchTerms}";
                Method = "GET";
              }
              {
                Name = "ARD";
                Alias = "@ard";
                URLTemplate = "https://www.ardmediathek.de/suche/{searchTerms}";
                Method = "GET";
              }
              {
                Name = "ProtonDB";
                Alias = "@protondb";
                URLTemplate = "https://www.protondb.com/search?q={searchTerms}";
                Method = "GET";
              }
              {
                Name = "SteamDB";
                Alias = "@steamdb";
                URLTemplate = "https://steamdb.info/search/?a=all&q={searchTerms}";
                Method = "GET";
                IconURL = steamdbIcon;
              }
              {
                Name = "Blender user manual";
                Alias = "@blender";
                URLTemplate = "https://docs.blender.org/manual/en/latest/search.html?q={searchTerms}&check_keywords=yes&area=default";
                Method = "GET";
                IconURL = blenderIcon;
              }
              {
                Name = "Wikipedia";
                Alias = "@wikipedia";
                URLTemplate = "https://en.wikipedia.org/wiki/Special:Search?go=Go&search={searchTerms}";
                Method = "GET";
                IconURL = wikipediaIcon;
              }
              {
                Name = "Wikidata";
                Alias = "@wd";
                URLTemplate = "https://www.wikidata.org/w/index.php?go=Go&search={searchTerms}";
                Method = "GET";
                IconURL = wikidataIcon;
              }
              {
                Name = "OpenStreetMap";
                Alias = "@osm";
                URLTemplate = "https://www.openstreetmap.org/search?query={searchTerms}";
                Method = "GET";
                IconURL = osmIcon;
              }
            ];

            Remove = [
              "Google"
              "Bing"
            ];
          };

          OverridePostUpdatePage = "";
          FirefoxHome = {
            Search = true;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Locked = true;
          };
          UserMessaging = {
            ExtensionsRecommendations = false;
            FeatureRecommendations = false;
            UrlbarInterventions = false;
            SkipOnboarding = true;
            MoreFromMozilla = false;
            Locked = true;
          };

          ExtensionSettings =
            let
              moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
              addon = short: {
                install_url = moz short;
                installation_mode = "force_installed";
              };
            in
            {
              "*" = {
                allowed_types = [
                  "extension"
                  "theme"
                  "locale"
                ];
              };
              "addon@darkreader.org" = addon "darkreader";
              "uBlock0@raymondhill.net" = addon "ublock-origin";
              "langpack-de@firefox.mozilla.org" = addon "deutsch-de-language-pack";
            };

          Preferences = {
            "extensions.activeThemeID" = {
              Value = "firefox-compact-dark@mozilla.org";
              Status = "default";
            };
          };
        };

      preferences =
        concatMapAttrs (prefix: mapKv (key: if prefix == "" then key else "${prefix}.${key}") id)
          {
            "" = {
              "browser.translations.automaticallyPopup" = false;
            };
            "browser.search.suggest" = {
              "enabled" = false;
              "enabled.private" = false;
              "addons" = false;
              "bestmatch" = false;
              "bookmark" = true;
              "engines" = true;
              "history" = false;
              "openpage" = false;
              "topsites" = false;
              "weather" = false;
            };
            "browser.urlbar" = {
              "placeholderName" = "nyaaa~~ rawr!! mrrp";
              "sponsoredTopSites" = false;
            };
            "browser.urlbar.suggest" = {
              "addons" = false;
              "bestmatch" = false;
              "bookmark" = true;
              "calculator" = true;
              "searches" = false;
              "engines" = false;
              "history" = false;
              "openpage" = false;
              "topsites" = false;
              "weather" = false;
            };
          };
    };

    steam = mkIf cfg.gaming {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };

  environment.etc."thunderbird/policies/policies.json".source =
    let
      json = (pkgs.formats.json { }).generate "thunderbird-policies.json";
      preferences = mapKv (key: "intl.date_time.pattern_override.${key}") (value: {
        Value = value;
        Status = "locked";
      });
    in
    json {
      policies = {
        Preferences =
          preferences
            # adjust to adhere to RFC 3339 (apart from the space separator)
            # and that even regardless of locale, whew
            # https://support.mozilla.org/en-US/kb/customize-date-time-formats-thunderbird
            {
              "date_short" = "yyyy-MM-dd";
              "time_short" = "HH:mm:ss";
              # {1} refers to the date, {0} to the time
              # any char other than `,` or ` ` has to be escaped in single-quotes
              "connector_short" = "{1} {0}";
            };
      };
    };
  nixpkgs = {
    config.allowUnfree = true;

    overlays = [ ];
  };

  system.copySystemConfiguration = true;
}
