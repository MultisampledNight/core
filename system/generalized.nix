# Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  lib,
  ...
}@args:

with lib;
with import ./prelude args;
let
  py = pkgs.python3.withPackages (ps: with ps; [ requests ]);
in
{
  options.generalized = {
    boot = mkOption {
      type = types.nullOr (
        types.enum [
          "uefi"
          "bios"
        ]
      );
      default = "uefi";
      description = ''
        How the firmware boots. Advice:

        - Most likely you want `"uefi"`.
        - If that doesn't work, only then use `"bios"`.
          - Make sure to set `boot.loader.grub.device`
            to the *disk* (not the partition!)
            you want GRUB to install to then.
          - Also, if that disk is partitioned using GPT,
            create a BIOS boot partition of a megabyte or so anywhere
            so GRUB can throw its code in it.
        - If you really want to handle booting yourself,
          e.g. for VM images, only then use `null`.
      '';
    };

    hostName = mkOption {
      type = types.strMatching "^$|^[[:alnum:]]([[:alnum:]_-]{0,61}[[:alnum:]])?$";
      default = "inconsistent";
      description = "The networking hostname of this system.";
    };

    layout = mkOption {
      type = types.str;
      default = "bone";
      description = ''
        What keyboard layout to use on the Linux console and
              in graphical environments.'';
    };

    cpuVendor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "What microcode updates to install.";
    };

    baremetal = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If this machine runs directly on real hardware.
        If `true`, firmware update and
        other hardware maintenance helpers are installed.
      '';
    };

    wireless.wlan = mkOption {
      type = types.bool;
      default = cfg.baremetal;
      description = "If to enable wireless services through iwd and iwctl.";
    };
    wireless.bluetooth = mkOption {
      type = types.bool;
      default = cfg.baremetal;
      description = "If to enable bluetooth.";
    };

    externalInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Which interface is designated to be exposed to the outside world.";
    };

    ssd = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable services like fstrim for automatic SSD maintenance.";
    };

    ssh = mkOption {
      type = types.bool;
      default = false;
      description = "If to expose an OpenSSH server.";
    };

    xorg = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable Xorg as display protocol with i3. Only in effect on non-server setups.";
    };

    wayland = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable Wayland as display protocol with sway.";
    };

    graphical = mkOption {
      type = types.bool;
      default = cfg.wayland || cfg.xorg;
      description = "If to install graphical applications. Automatically enabled if you enable a display protocol.";
    };

    hidpi = mkOption {
      type = types.bool;
      default = false;
      description = "If this system has a high display resolution on a relatively small surface. Causes most elements to be scaled up and a larger font size in the console.";
    };

    audio = mkOption {
      type = types.bool;
      default = false;
      description = "If this system should have PipeWire with compatibility plugins installed and running.";
    };

    video.driver = mkOption {
      type = (
        with types;
        nullOr (oneOf [
          str
          (attrsOf str)
        ])
      );
      default = null;
      example = {
        "0000:0000" = "i915";
        "0000:0001" = "nouveau";
      };
      description = ''
        Video driver selection and preferences.

        If set to a string, that's the only driver installed.
        Usually the driver is smart enough to figure out
        what the installed cards are and
        which ones should be initialized.
        This is the most common setup.

        If set to an attribute set,
        the keys determine
        which (case-insensitive) PCI IDs use
        which driver,
        done via an override mechanism.
        Multiple PCI devices can use the same driver
        (but not the other way around).

        You can find the PCI ID for your card
        by running `lspci -nn | grep -i vga`,
        it's the last square brackets and
        in the form of `vendor:device`,
        where `vendor` and `device` are both 4 hexadecimal digits.

        (This is specifically useful for using older NVIDIA cards
        together with newer ones,
        since by default the proprietary one will bind first
        to all cards,
        leaving the nouveau one puzzled (simplified).)
      '';
    };

    video.prefer = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Which video driver to use by default for e.g. Vulkan.

        You can change this at runtime for Vulkan and a program run
        e.g. by using the `VK_LOADER_DRIVERS_SELECT` environment variable,
        see https://vulkan.lunarg.com/doc/view/1.3.243.0/linux/LoaderDriverInterface.html#user-content-driver-select-filtering.
      '';
    };

    camera = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If to configure webcams and
        the works.

        If disabled (the default),
        the `uvcvideo` kernel module
        is not loaded by default.
      '';
    };

    profileGuided = mkOption {
      type = types.bool;
      default = false;
      description = "If to compile a few packages locally and adjusted to this CPU for better performance. Note that this will inherently make this configuration irreproducible on a platform that is only slightly different.";
    };

    gaming = mkOption {
      type = types.bool;
      default = false;
      description = "If you are the type of person which is colloquially referred to as gamer. Only in effect on non-server setups.";
    };

    multimedia = mkOption {
      type = types.bool;
      default = false;
      description = "If you want to record, produce and edit videos, music and audio. Only in effect on non-server setups.";
    };
  };

  imports = [ ./development.nix ];

  config = {
    assertions = [
      {
        assertion =
          !(isAttrs cfg.video.prefer) || (contains cfg.video.prefer (attrValues cfg.video.driver));
        message = "The preferred video driver has to be one of the used ones";
      }
    ];

    boot = {
      loader =
        if cfg.boot == "uefi" then
          {
            systemd-boot = {
              enable = true;
              editor = false;
              consoleMode = "auto";
              configurationLimit = 256;
            };
            grub.enable = false;
            efi.canTouchEfiVariables = true;
          }
        else if cfg.boot == "bios" then
          {
            grub.enable = true;
          }
        else
          {
            grub.enable = mkDefault false;
          };

      kernelPackages = mkDefault (
        if cfg.profileGuided then
          pkgs.unstable.linuxZenFast
        else
          pkgs.unstable.linuxKernel.packages.linux_zen
      );

      tmp.cleanOnBoot = true;

      kernelParams = optionals hasNv [ "nvidia-drm.fbdev=1" ];
      blacklistedKernelModules = optionals (!cfg.camera) [ "uvcvideo" ];
    };

    console.colors = [
      "212224" # black
      "ff9365" # red
      "11d396" # green
      "c7b700" # yellow
      "00c7f7" # blue
      "fa86ce" # magenta
      "aaa9ff" # cyan
      "b6b3b4" # white
      "7f7dcc" # bright black aka grey
      "ff9365" # bright red
      "11d396" # bright green
      "c7b700" # bright yellow
      "00c7f7" # bright blue
      "fa86ce" # bright magenta
      "aaa9ff" # bright cyan
      "b6b3b4" # bright white
    ];

    hardware = {
      cpu.intel.updateMicrocode = cfg.cpuVendor == "intel";
      cpu.amd.updateMicrocode = cfg.cpuVendor == "amd";

      bluetooth.enable = cfg.wireless.bluetooth;

      graphics = {
        enable = true;
        extraPackages =
          with pkgs;
          selectForDrivers {
            i915 = [
              mesa
              intel-media-driver
              intel-compute-runtime.drivers
            ];
            nouveau = [ mesa ];
          };

        enable32Bit = true;
        extraPackages32 =
          with pkgs.pkgsi686Linux;
          selectForDrivers {
            i915 = [ mesa ];
            nouveau = [ mesa ];
          };
      };

      nvidia = mkIf hasNv {
        modesetting.enable = true;
        powerManagement.enable = true;
        open = true;
      };
    };

    networking = {
      hostName = cfg.hostName;
      wireless.iwd.enable = cfg.wireless.wlan;
      networkmanager.enable = false;

      nat = mkIf (cfg.externalInterface != null) {
        enable = true;
        enableIPv6 = true;
        externalInterface = cfg.externalInterface;
      };
    };
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font = if cfg.hidpi then null else "Lat2-Terminus16";

      keyMap = cfg.layout;
    };

    users = {
      defaultUserShell = pkgs.zsh;

      users.multisn8 = {
        isNormalUser = true;
        extraGroups =
          [
            "wheel"
            "plugdev"
            "antisuns"
            "kvm"
            "scanner"
            "lp"
            "dialout"
          ]
          ++ (optionals cfg.graphical [
            "input"
            "video"
            "audio"
          ])
          ++ (optionals config.programs.adb.enable [ "adbusers" ]);
        shell = pkgs.zsh;
        createHome = true;
      };

      groups = {
        plugdev = { };
      };
    };

    services = {
      fstrim.enable = cfg.ssd;
      fwupd = {
        enable = cfg.baremetal;
        # see fwupd.conf(5)
        daemonSettings = {
          # do not fallback to unsafe http (which it does by default)
          UriSchemes = [
            "https"
            "ipfs"
          ];
          ShowDevicePrivate = false;
        };
      };
      thermald.enable = cfg.baremetal;

      gpm.enable = true;

      displayManager.enable = lib.mkForce false;
      xserver.displayManager.lightdm.enable = lib.mkForce false;

      openssh = {
        enable = cfg.ssh;
        startWhenNeeded = true;

        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      # audio server
      pipewire = {
        enable = cfg.audio;
        alsa.enable = cfg.audio;
        pulse.enable = cfg.audio;
        jack.enable = cfg.audio;
        wireplumber.enable = cfg.audio;

        alsa.support32Bit = true;
      };

      # see udev(7)
      udev.extraRules =
        let
          sh = getBin pkgs.bash;
          # only need to apply udev overrides
          # if there's an override mapping by the user
          # otherwise just rely on default behavior, it'll be fine
          videoDrivers = optString (isAttrs cfg.video.driver) (
            toString (
              mapAttrsToList (
                id: driver:
                let
                  parts = splitString ":" (toLower id);
                  vendor = elemAt parts 0;
                  device = elemAt parts 1;

                  runExtra =
                    {
                      nouveau = "${getBin pkgs.kmod}/bin/modprobe nouveau";
                    }
                    .${driver} or null;
                  run = optString (runExtra != null) '', RUN+="${runExtra}"'';

                  condition = ''SUBSYSTEM=="pci", ATTRS{vendor}=="0x${vendor}", ATTRS{device}=="0x${device}"'';
                  action = ''ATTR{driver_override}="${driver}"'' + run;
                in
                ''
                  ${condition}, ${action}
                ''
              ) cfg.video.driver
            )
          );
        in
        ''
          # Quest 1
          SUBSYSTEM=="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE:="0666", GROUP:="plugdev"

          # Device rules for Intel RealSense devices (D405)
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0666", GROUP:="plugdev"

          # Intel RealSense recovery devices (DFU)
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ab3", MODE:="0666", GROUP:="plugdev"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adb", MODE:="0666", GROUP:="plugdev"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adc", MODE:="0666", GROUP:="plugdev"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b55", MODE:="0666", GROUP:="plugdev"

          KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0777", GROUP:="plugdev", RUN+="${sh} -c 'chmod -R 0777 /sys/%p'"
          DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", RUN+="${sh} -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"

          # FT232 DMX <-> USB interface
          SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6001", MODE="0666", GROUP="plugdev"

          ${videoDrivers}
        '';
    };

    environment = {
      systemPackages = unite [
        (with pkgs; [
          [
            true
            [
              curl
              rsync
              rclone
              yt-dlp
              magic-wormhole-rs
              dogdns
              gptfdisk
              nvme-cli
              efibootmgr
              smartmontools
              usbutils
              cyme
              tio
              traceroute
              tcpdump
              mtr
              iperf
              oniux
              dtc
              fd
              ripgrep
              tree
              file
              pv
              mpv
              jq
              yq
              htmlq
              unzip
              zip
              sqlite-interactive
              btop
              sysstat
              cryptsetup
              hexyl
              libguestfs
              fbida
              hyperfine
              nix-bundle
              # i had to look that up manually in the nixpkgs source tree under
              # <nixpkgs/pkgs/development/libraries/aspell/dictionaries.nix>
              # this function is not documented anywhere.
              (aspellWithDicts (
                dicts: with dicts; [
                  de # German
                  en # English
                  eo # Esperanto
                  fi # Finnish
                  nl # Dutch
                  pl # Polish
                  ru # Russian
                  sv # Swedish
                  uk # Ukrainian
                  vi # Vietnamese
                ]
              ))
            ]
          ]
          [
            cfg.wireless.wlan
            [ iw ]
          ]
          [
            cfg.xorg
            [ xclip ]
          ]
          [
            cfg.graphical
            [
              wf-recorder
              oxipng
              qalculate-gtk
              glib
              # themes
              adapta-gtk-theme
              adapta-kde-theme
              volantes-cursors
            ]
          ]
        ])
        (with unstable; [
          [
            true
            [
              py
              julia
              waypipe
              pynitrokey
              opensc
              ffmpeg-full
            ]
          ]
          [
            cfg.wayland
            [
              fuzzel
              waybar
              grim
              slurp
              swappy
              hyprpicker
              fnott
              swaybg
              swaylock
              wl-clipboard
            ]
          ]
          [
            cfg.graphical
            [ alacritty ]
          ]
        ])
      ];

      sessionVariables =
        {
          TYPST_FONT_PATHS = optString config.fonts.fontDir.enable "/run/current-system/sw/share/X11/fonts"; # not sure if I should upstream this
        }
        // (optAttrs cfg.wayland {
          QT_PLUGIN_PATH = map (plugin: "${plugin}/lib") (with pkgs; [ libsForQt5.qtwayland ]);
          XDG_CURRENT_DESKTOP = "sway";
        });

      gnome.excludePackages = with pkgs.gnome; [
        cheese
        epiphany
        geary
        tali
        iagno
        hitori
        atomix
        evince
      ];
      shells = with pkgs; [
        bashInteractive
        zsh
      ];
    };

    programs = {
      git = {
        enable = true;
        config = {
          init.defaultBranch = "main";
          commit.gpgsign = true;
          core.editor = "nvim";
          color.pager = "off";
        };
      };

      neovim = {
        enable = true;
        vimAlias = true;
        viAlias = true;
      };

      sway = {
        enable = cfg.wayland;
        package = pkgs.unstable.sway;
        extraSessionCommands = ''
          export SDL_VIDEODRIVER=wayland
          export QT_QPA_PLATFORM=wayland-egl
          export ECORE_EVAS_ENGINE=wayland_egl
          export ELM_ENGINE=wayland_egl
          export _JAVA_AWT_WM_NONREPARENTING=1
        '';

        extraOptions = optional hasNv "--unsupported-gpu";

        wrapperFeatures.gtk = true;
      };

      # shell
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        promptInit =
          let
            cfg = {
              timeFormat = "%H %M";
              sign = {
                root = "#";
                user = "=";
                # ANSI base16 color
                color = toString (machine.accent + 1);
              };
            };

            part = with cfg; {
              date = "%D{${timeFormat}}";
              sign = "%F{${sign.color}}%(!.${sign.root}.${sign.user})%f";
              exitCode = "%(?..%F{1}%?%f)";
              cwd = "%F{5}%~%f";
              machine = "%F{4}@%M%f";
            };

            seq = mapValue toString (
              with part;
              {
                left = [
                  date
                  sign
                ];
                right = [
                  exitCode
                  cwd
                  machine
                ];
              }
            );
          in
          with seq;
          ''
            PROMPT=' ${left} '
            RPROMPT='${right}'
          '';
      };
    };

    # the default is hourly for some reason
    systemd.timers.fwupd-refresh.timerConfig = {
      OnCalendar = "weekly";
    };

    xdg = {
      portal = mkIf cfg.graphical {
        enable = true;
        extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      };
      mime = {
        enable = true;
        defaultApplications =
          let
            editor = "neovide.desktop";
            associate =
              {
                key,
                values,
                target ? editor,
              }:
              listToAttrs (
                map (value: {
                  name = "${key}/${value}";
                  value = target;
                }) values
              );
            langs =
              category: values:
              associate {
                key = category;
                values = values;
              };
            nonstandard = map (value: "x-${value}");
          in
          {
            "application/pdf" = "org.gnome.Evince.desktop";
            "application/json" = "neovide.desktop";
          }
          // (langs "application" (
            [
              "javascript"
              "json"
              "toml"
              "yaml"
              "xml"
              "sql"
              "zip"
            ]
            ++ (nonstandard [
              "java"
              "php"
              "csh"
              "nuscript"
              "bat"
              "powershell"
              "qml"
              "tar"
            ])
          ))
          // (langs "text" (
            [
              "julia"
              "rust"
              "csv"
              "csv-schema"
              "css"
              "markdown"
              "org"
              "plain"
            ]
            ++ (nonstandard [
              "csharp"
              "erlang"
              "java"
              "kotlin"
              "lua"
              "python"
              "sagemath"
              "vala"
              "pascal"
              "nim"
              "nimscript"
              "go"
              "vhdl"
              "verilog"
              "sass"
              "scss"
              "todo-txt"
              "readme"
              "nfo"
            ])
          ));
      };
    };
    qt = {
      enable = true;
      style = "adwaita-dark";
    };

    security.sudo.extraConfig =
      with term;
      toSudoers {
        # see sudoers(5)
        passwd_timeout = 0;
        timestamp_type = "global";

        passprompt = "${indent}${query} auth for %u${cha 8}";
        badpass_message = "${indent}${error} wrong password";
        authfail_message = " ${error} %d time(s) incorrect";
      };

    virtualisation = {
      vmVariant = {
        virtualisation.resolution = {
          x = 1920;
          y = 1080;
        };

        services.getty.autologinUser = "multisn8";
        users = {
          mutableUsers = false;
          users.multisn8.initialHashedPassword = "";
        };
      };
    };

    nixpkgs.overlays =
      let
        unstablePkgs = import <nixos-unstable> {
          config = {
            allowUnfreePredicate =
              pkg:
              (
                (builtins.elem (lib.getName pkg) [
                  "nvidia-x11"
                  "nvidia-settings"
                  # those below are all just for CUDA it's so joever
                  "libnpp"
                ])
                || (any (prefix: hasPrefix prefix (lib.getName pkg)) [
                  "cuda"
                  "libcu"
                  "libnv"
                ])
              );
          };

          overlays = [
            (final: prev: {
              # updating so we can customize the short animation length
              # the weird double-override is needed due to how the vendoring is implemented
              # https://nixos.wiki/wiki/Rust#Using_overrideArgs_with_Rust_Packages
              neovide = overrideRust prev.neovide {
                src = pkgs.fetchFromGitHub {
                  owner = "neovide";
                  repo = "neovide";
                  rev = "627956990b4d85a2a98a13e0c50da2155d15cd72";
                  hash = "sha256-WwLEL6GyLLPbGEJrpSRLTJr+CqevZZ5MBZNUbXLWn3I=";
                };
                cargoHash = "sha256-1ni8AZIwAz5R2Ejt9Fj5qmybvL4KZV/M3BMqQx4HFLU=";
              };
            })
            (
              final: prev:
              optAttrs cfg.profileGuided {
                godot_4 = prev.godot_4.override { stdenv = final.fastStdenv; };
                ffmpeg-full = prev.ffmpeg-full.override { stdenv = final.fastStdenv; };
                linuxZenFast = prev.linuxPackagesFor (
                  prev.linuxKernel.kernels.linux_zen.override {
                    stdenv = final.fastStdenv;
                  }
                );
              }
            )
            (final: prev: {
              julia = prev.julia.withPackages [
                "LanguageServer"
              ];
            })
            (final: prev: {
              blender = prev.blender.overrideAttrs (pAttr: {
                patches = pAttr.patches ++ [
                  # https://projects.blender.org/blender/blender/issues/119901
                  ./packages/blender/openxr-wayland.patch
                ];
              });
            })
          ];
        };
      in
      [
        (final: prev: {
          unstable = unstablePkgs;
          custom = import ./packages { pkgs = unstablePkgs; };
        })
        (final: prev: {
          mpv = prev.mpv.override { scripts = with final.mpvScripts; [ mpris ]; };
          # https://github.com/nix-community/nix-bundle/pull/120
          # makes it runnable again (function was removed in nixpkgs)
          nix-bundle = prev.nix-bundle.overrideAttrs {
            src = pkgs.fetchFromGitHub {
              owner = "matthewbauer";
              repo = "nix-bundle";
              rev = "84638f4a8cff38f7a023b2a89c5209cde5ed9534";
              hash = "sha256-J/PvGqz5DOJ4Fmf47XbwgpdpfZ+ALIZFI304UNtS2XU=";
            };
          };
        })
      ];
    nix = {
      package = pkgs.lix;
      settings = {
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
    };
  };
}
