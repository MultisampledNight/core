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
    wivrn = {
      enable = true;
      defaultRuntime = true;
      openFirewall = true;
      autoStart = true;
    };

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
          [
            layaway
            nyandere
          ]
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
      package = pkgs.firefox-esr-140;
      # https://mozilla.github.io/policy-templates/
      policies = {
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
              "Rust releases" = "https://releases.rs/";

              "The Little Book of Rust Macros" = "https://lukaswirth.dev/tlborm/";
              "The Rust Programming Language Book" = "https://doc.rust-lang.org/stable/book/";

              "Julia docs" = "https://docs.julialang.org/en/v1/";
              "Julia LinearAlgebra" = "https://docs.julialang.org/en/v1/stdlib/LinearAlgebra/";

              "Blender" = "https://www.blender.org/";
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
            }
            {
              Name = "Rust crate registry";
              Alias = "@rspkgs-slow";
              URLTemplate = "https://crates.io/search?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Python package index";
              Alias = "@pypkgs";
              URLTemplate = "https://pypi.org/search/?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Arch Linux packages";
              Alias = "@archpkgs";
              URLTemplate = "https://archlinux.org/packages/?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Nix packages";
              Alias = "@nixpkgs";
              URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Arch wiki";
              Alias = "@archdoc";
              URLTemplate = "https://wiki.archlinux.org/index.php?search={searchTerms}&title=Special%3ASearch";
              Method = "GET";
            }
            {
              Name = "Arch manual pages";
              Alias = "@man";
              URLTemplate = "https://man.archlinux.org/search?q={searchTerms}&go=Go";
              Method = "GET";
            }
            {
              Name = "Python stdlib documentation";
              Alias = "@pydoc";
              URLTemplate = "https://docs.python.org/3/search.html?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Rust stdlib documentation";
              Alias = "@rsdoc";
              URLTemplate = "https://doc.rust-lang.org/std/index.html?search={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Rust crate documentation";
              Alias = "@rsext";
              URLTemplate = "https://docs.rs/releases/search?query={searchTerms}&sort=recent-downloads";
              Method = "GET";
            }
            {
              Name = "Java SE 21 API reference";
              Alias = "@javase21";
              URLTemplate = "https://docs.oracle.com/en/java/javase/21/docs/api/search.html?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "NixOS options";
              Alias = "@nixopts";
              URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
              Method = "GET";
            }
            {
              Name = "NixOS wiki";
              Alias = "@nixdoc";
              URLTemplate = "https://nixos.wiki/index.php?search={searchTerms}&go=Go";
              Method = "GET";
            }
            {
              Name = "postmarketOS Wiki";
              Alias = "@pmosdoc";
              URLTemplate = "https://wiki.postmarketos.org/index.php?search={searchTerms}&title=Special%3ASearch";
              Method = "GET";
            }
            {
              Name = "MDN Web Docs";
              Alias = "@webdoc";
              URLTemplate = "https://developer.mozilla.org/en-US/search?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Typst universe";
              Alias = "@typpkgs";
              URLTemplate = "https://typst.app/universe/search?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Sourcegraph";
              Alias = "@code-srcgrph";
              URLTemplate = "https://sourcegraph.com/search?q=context:global+{searchTerms}&patternType=keyword&sm=0";
              Method = "GET";
            }
            {
              Name = "Bandcamp";
              Alias = "@bandcamp";
              URLTemplate = "https://bandcamp.com/search?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "media.ccc.de";
              Alias = "@mediaccc";
              URLTemplate = "https://media.ccc.de/search/?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "YouTube";
              Alias = "@youtube";
              URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
              Method = "GET";
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
              Name = "3sat";
              Alias = "@3sat";
              URLTemplate = "https://www.3sat.de/suche?q={searchTerms}&synth=true&attrs=";
              Method = "GET";
            }
            {
              Name = "ARTE";
              Alias = "@arte";
              URLTemplate = "https://www.arte.tv/en/search/?q=mreow&genre=all";
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
            }
            {
              Name = "Blender user manual";
              Alias = "@blender";
              URLTemplate = "https://docs.blender.org/manual/en/latest/search.html?q={searchTerms}&check_keywords=yes&area=default";
              Method = "GET";
            }
            {
              Name = "Wikipedia";
              Alias = "@wikipedia";
              URLTemplate = "https://en.wikipedia.org/wiki/Special:Search?go=Go&search={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Wikidata";
              Alias = "@wd";
              URLTemplate = "https://www.wikidata.org/w/index.php?go=Go&search={searchTerms}";
              Method = "GET";
            }
            {
              Name = "On-Line Encyclopedia of Integer Sequences";
              Alias = "@oeis";
              URLTemplate = "https://oeis.org/search?go=Search&q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "OpenStreetMap";
              Alias = "@osm";
              URLTemplate = "https://www.openstreetmap.org/search?query={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Mouser";
              Alias = "@mouser";
              URLTemplate = "https://www.mouser.de/c/?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "DigiKey";
              Alias = "@digikey";
              URLTemplate = "https://www.digikey.de/en/products/result?keywords={searchTerms}";
            }
            {
              Name = "Mrose";
              Alias = "@mrose";
              URLTemplate = "https://mrose.de/suche/?p3={searchTerms}";
              Method = "GET";
            }
            {
              Name = "AbS Lieder";
              Alias = "@abslieder";
              URLTemplate = "https://www.abs-lieder.de/advanced_search_result.php?categories_id=&inc_subcat=1&keywords={searchTerms}";
              Method = "GET";
            }
            {
              Name = "Täubner Arbeitskleidung";
              Alias = "@abstäubner";
              URLTemplate = "https://www.taeubner-arbeitskleidung.de/suche?suchtxt={searchTerms}";
              Method = "POST";
            }
            {
              Name = "HELE";
              Alias = "@hele";
              URLTemplate = "https://www.hele.de/eShop/index.php?lang=0&cl=search&searchparam={searchTerms}";
              Method = "GET";
            }
            {
              Name = "BuyDisplay";
              Alias = "@buydisplay";
              URLTemplate = "https://www.buydisplay.com/catalogsearch/result/?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "The Free Dictionary";
              Alias = "@tfd";
              URLTemplate = "https://www.thefreedictionary.com/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "Free Thesaurus";
              Alias = "@fts";
              URLTemplate = "https://www.freethesaurus.com/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "Duden";
              Alias = "@duden";
              URLTemplate = "https://www.duden.de/suchen/dudenonline/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "Save now on Wayback Machine";
              Alias = "@savewm";
              URLTemplate = "https://web.archive.org/save/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "WolframAlpha";
              Alias = "@wolfal";
              URLTemplate = "https://www.wolframalpha.com/input?i={searchTerms}";
              Method = "GET";
            }
            {
              Name = "DOI resolver";
              Alias = "@doi";
              URLTemplate = "https://dx.doi.org/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "Semantic Scholar";
              Alias = "@semsch";
              URLTemplate = "https://www.semanticscholar.org/search?q={searchTerms}&sort=relevance";
              Method = "GET";
            }
            {
              Name = "Connected Papers";
              Alias = "@conn-papers";
              URLTemplate = "https://www.connectedpapers.com/search?q={searchTerms}";
              Method = "GET";
            }
            {
              Name = "PubMed";
              Alias = "@pubmed";
              URLTemplate = "https://pubmed.ncbi.nlm.nih.gov/?term={searchTerms}";
              Method = "GET";
            }
            # CAUTION: all of these are *preprint* servers, not peer reviewed! do not rely on these for anything.
            {
              Name = "arXiv";
              Alias = "@arxiv";
              URLTemplate = "https://arxiv.org/search/?query={searchTerms}&searchtype=all&source=header";
              Method = "GET";
            }
            {
              Name = "bioRxiv";
              Alias = "@biorxiv";
              URLTemplate = "https://www.biorxiv.org/search/{searchTerms}";
              Method = "GET";
            }
            {
              Name = "medRxiv";
              Alias = "@medrxiv";
              URLTemplate = "https://www.medrxiv.org/search/{searchTerms}";
              Method = "GET";
            }
            # gaming
            {
              Name = "Speedrun.com";
              Alias = "@speedrun";
              URLTemplate = "https://www.speedrun.com/search?q={searchTerms}";
              Method = "GET";
            }
            # law
            {
              # EU cases and legislation
              Name = "EUR-Lex";
              Alias = "@eurlex";
              URLTemplate = "https://eur-lex.europa.eu/search.html?scope=EURLEX&lang=en&text={searchTerms}";
              Method = "GET";
            }
            {
              # national legislation
              Name = "N-Lex";
              Alias = "@nlex";
              URLTemplate = "https://n-lex.europa.eu/n-lex/aggregated-results?search=multi&selectedCorpus=bg.apis.soap,cz.legis.sbirka,de.legis.juris,ee.legis.start,ee.legis.total,hu.jogszabalytar,ie.legis.sbook,lv.legis.vestnesis,ro.legis.iservice,sv.legis.fulltext&selectedCountries=bg,cz,de,ee,hu,ie,lv,ro,sv,&textSearchPosition=title,text&allCountries=true&words_in_title={searchTerms}&words_in_text1={searchTerms}";
              Method = "GET";
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
            "uBlock0@raymondhill.net" = addon "ublock-origin";
            "jid1-BoFifL9Vbdl2zQ@jetpack" = addon "decentraleyes";
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
  programs.obs-studio = mkIf cfg.multimedia {
    enable = true;
    enableVirtualCamera = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vkcapture
      obs-pipewire-audio-capture
      input-overlay
    ];
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
  };

  system.copySystemConfiguration = true;
}
