# Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... } @ args:

with lib;
with import ./prelude args;
{
  options.generalized = {
    boot = mkOption {
      type = types.nullOr (types.enum ["uefi" "bios"]);
      default = "uefi";
      description = ''
        How the interface talks to the firmware. Advice:

        - Most likely you want `"uefi"`.
        - If that doesn't work, only then use `"bios"`.
        - If you really want to handle booting yourself,
          e.g. for VM images, only then use `null`.
      '';
    };

    hostName = mkOption {
      type = types.strMatching
        "^$|^[[:alnum:]]([[:alnum:]_-]{0,61}[[:alnum:]])?$";
      default = "inconsistent";
      description = "The networking hostname of this system.";
    };

    layout = mkOption {
      type = types.str;
      default = "bone";
      description = "What keyboard layout to use on the Linux console and
      in graphical environments.";
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
        If that is the case, firmware update and other hardware maintenance helpers are installed.
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
      description = "If to enable services like fstrim for automatic SSD maintenace.";
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
      description = "If this system should have PipeWire with compatability plugins installed and running.";
    };

    profileGuided = mkOption {
      type = types.bool;
      default = false;
      description = "If to compile a few packages locally and adjusted to this CPU for better perfomance. Note that this will inherently make this configuration irreproducable on a platform that is only slightly different.";
    };

    videoDriver = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "What video driver to use for Xorg. Only in effect on development setups.";
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

  imports = [./development.nix];

  config = {
    boot = {
      loader = if cfg.boot == "uefi" then {
        systemd-boot = {
          enable = true;
          editor = false;
          consoleMode = "auto";
          configurationLimit = 256;
        };
        grub.enable = false;
        efi.canTouchEfiVariables = true;
      } else if cfg.boot == "bios" then {
        grub.enable = true;
      } else {};

      kernelPackages = mkDefault (
        if cfg.profileGuided
        then pkgs.unstable.linuxZenFast
        else pkgs.unstable.linuxKernel.packages.linux_zen
      );

      tmp.cleanOnBoot = true;

      kernelParams = condList (cfg.videoDriver == "nvidia") [
        "nvidia-drm.fbdev=1"
      ];
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
      pulseaudio.enable = false; # handled by pipewire-pulse instead

      cpu.intel.updateMicrocode = cfg.cpuVendor == "intel";
      cpu.amd.updateMicrocode = cfg.cpuVendor == "amd";

      bluetooth.enable = cfg.wireless.bluetooth;

      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true; # :clueless:
        extraPackages = with pkgs; {
          intel = [mesa.drivers intel-media-driver intel-compute-runtime];
          nvidia = [config.hardware.nvidia.package];
        }.${cfg.videoDriver} or [];
        extraPackages32 = condList
          (cfg.videoDriver == "nvidia")
          [config.hardware.nvidia.package.lib32];
      };

      nvidia = if cfg.videoDriver == "nvidia"
        then {
          modesetting.enable = true;
          powerManagement.enable = true;
          open = true;
        }
        else {};
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
      font =
        if cfg.hidpi
        then null
        else "Lat2-Terminus16";

      keyMap = cfg.layout;
    };

    users = {
      defaultUserShell = pkgs.zsh;

      users.multisn8 = {
        isNormalUser = true;
        extraGroups =
          ["wheel" "plugdev" "antisuns" "kvm" "scanner" "lp"]
          ++ (condList cfg.graphical ["input" "video" "audio"])
          ++ (condList config.programs.adb.enable ["adbusers"]);
        shell = pkgs.zsh;
      };

      groups = {
        plugdev = {};
      };
    };

    services = {
      fstrim.enable = cfg.ssd;
      fwupd.enable = cfg.baremetal;
      thermald.enable = cfg.baremetal;

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

      udev.extraRules = ''
        # Quest 1
        SUBSYSTEM=="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE="0666", GROUP="plugdev"

        # Device rules for Intel RealSense devices (D405)
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0666", GROUP:="plugdev"

        # Intel RealSense recovery devices (DFU)
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ab3", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adb", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adc", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b55", MODE:="0666", GROUP:="plugdev"

        KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0777", GROUP:="plugdev", RUN+="${lib.getBin pkgs.bash} -c 'chmod -R 0777 /sys/%p'"
        DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", RUN+="${lib.getBin pkgs.bash} -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      '';

      system76-scheduler.enable = true;
    };

    environment = {
      systemPackages = unite [
        (with pkgs; [
          [true [
            curl rsync rclone magic-wormhole-rs
            gptfdisk efibootmgr usbutils
            traceroute
            fd ripgrep
            tree
            file pv
            ffmpeg mpv jq unzip zip
            sqlite-interactive
            btop sysstat
            hexyl

            unstable.helix
          ]]
          [cfg.wireless.wlan [iw]]
          [cfg.xorg [xclip]]
          [cfg.graphical [
            speedcrunch
            qalculate-gtk
            glib
            # themes
            adapta-gtk-theme adapta-kde-theme
            breeze-icons volantes-cursors
          ]]
        ])
        (with unstable; [
          [true [python3]]
          [cfg.wayland [
            fuzzel waybar grim slurp swappy hyprpicker fnott
            swaybg swaylock wl-clipboard
            waypipe
          ]]
          [cfg.graphical [
            alacritty
          ]]
        ])
      ];

      sessionVariables = {
        TYPST_FONT_PATHS =
          if config.fonts.fontDir.enable
          then "/run/current-system/sw/share/X11/fonts"  # not sure if I should upstream this
          else "";
      } // (if cfg.wayland then {
        QT_PLUGIN_PATH = map (plugin: "${plugin}/lib") (with pkgs; [libsForQt5.qtwayland]);
        XDG_CURRENT_DESKTOP = "sway";
      } else {});

      shellAliases = {
        l = "ls -lh --group-directories-first --sort ext";
        ll = "l -a";
        c = "clear";
        help = "man";
      };

      gnome.excludePackages = with pkgs.gnome; [
        cheese epiphany geary tali iagno hitori atomix evince
      ];
      shells = with pkgs; [bashInteractive zsh];
    };

    programs = {
      git = {
        enable = true;
        config = {
          init.defaultBranch = "main";
          commit.gpgsign = true;
          core = {
            pager = "nvim -R";
            editor = "nvim";
          };
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
          export QT_WAYLAND_FORCE_DPI=physical
          export ECORE_EVAS_ENGINE=wayland_egl
          export ELM_ENGINE=wayland_egl
          export _JAVA_AWT_WM_NONREPARENTING=1
        '';

        extraOptions = if cfg.videoDriver == "nvidia"
          then ["--unsupported-gpu"]
          else [];

        wrapperFeatures.gtk = true;
      };

      # shell
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        promptInit = ''
          sign_color='6'
          if [[ $HOST == "elusive" ]]; then
            sign_color='2'
          fi
          PROMPT=" %D{%H %M} %F{$sign_color}%(!.#.=)%f "
          RPROMPT='%(?..%F{1}%?%f) %F{5}%~%f %F{4}@%M%f'
        '';
      };
    };

    xdg.portal = mkIf cfg.graphical {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
    };
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    security.sudo.extraConfig = with term; toSudoers {
      # see sudoers(5)
      passwd_timeout = 0;
      timestamp_type = "global";

      passprompt = "${indent}${query} auth for %u${cha 8}";
      badpass_message = "${indent}${error} wrong password";
      authfail_message = " ${error} %d time(s) incorrect";
    };

    virtualisation = {
      libvirtd.enable = true;
      kvmgt.enable = true;
    };

    nixpkgs.overlays = let
      unstablePkgs = import <nixos-unstable> {
        config = {
          allowUnfreePredicate = pkg: (
            (builtins.elem (lib.getName pkg) [
              "nvidia-x11"
              "nvidia-settings"
              "vimplugin-treesitter-grammar-cuda_merged"
              "blender"
              # those below are all just for CUDA it's so joever
              "libnpp"
            ]) || (
              any
                (prefix: hasPrefix prefix (lib.getName pkg))
                ["cuda" "libcu" "libnv"]
            )
          );
        };

        overlays = [
          (final: prev: if cfg.profileGuided then {
            godot_4 = prev.godot_4.override {
              stdenv = final.fastStdenv;
            };
          } else {})
          (final: prev: if cfg.profileGuided then {
            linuxZenFast = prev.linuxPackagesFor (prev.linuxKernel.kernels.linux_zen.override {
              stdenv = final.fastStdenv;
            });
          } else {})
          (final: prev: if (cfg.videoDriver == "nvidia") then {
            blender = prev.blender.override {
              cudaSupport = true;
            };
          } else {})
        ];
      };
    in [
      (final: prev: {
        unstable = unstablePkgs;
        custom = import ./packages { pkgs = prev; };
      })
      (final: prev: {
        mpv = prev.mpv.override {
          scripts = with final.mpvScripts; [
            mpris
          ];
        };
      })
    ];
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };
}
