{ name }:
{ config, lib, pkgs, modulesPath, ... }:

with lib;
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
  system = config.system;

  shells = map
    (shell: pkgs.callPackage
      ../../nix/shells/${shell}/default.nix
      {}
    )
    [
      "elixir"
      "julia"
      "python"
      "rust"
      "sdl"
      "typst"
    ];

  # set up common things and symlinks for my workflow when actually working
  rootTemplate = pkgs.runCommand
    "root-template"
    rec {
      configPatch = ./config.patch;
      configRepo = ../..;
      buildInputs = with pkgs; [ python3 ];
      toolchain = pkgs.stdenv.hostPlatform.config;

      nixos = pkgs.fetchzip {
        # nixos-24.05 on 2024-10-06
        name = "nixos-elusive";
        url = "https://github.com/nixos/nixpkgs/archive/ecbc1ca8ffd6aea8372ad16be9ebbb39889e55b6.tar.gz";
        hash = "sha256-PbDWAIjKJdlVg+qQRhzdSor04bAPApDqIv2DofTyynk=";
      };
      nixosUnstable = pkgs.fetchzip {
        # nixos-unstable on 2024-10-05
        name = "nixos-unstable-elusive";
        url = "https://github.com/nixos/nixpkgs/archive/bc947f541ae55e999ffdb4013441347d83b00feb.tar.gz";
        hash = "sha256-NOiTvBbRLIOe5F6RbHaAh6++BNjsb149fGZd1T4+KBg=";
      };

      rustChannel = "stable";
      rustInstall = ~/.rustup/toolchains/${rustChannel}-${toolchain};
      rustupSettings = ~/.rustup/settings.toml;
    }
    ''
      mkdir $out
      user=multisn8
      home=$out/home/$user

      # despite its name (TODO: change that sometime) it can also take care of copying configs, shells, the works
      python \
        $configRepo/distribute_symlinks.py \
        --exclude-nixos --actually-install \
        --root $out --user $user

      # adjust some things to fit to a VM
      chmod -R 777 $out
      patch -p1 -i $configPatch -d $out

      # "installing" Rust by just copying it from the host
      mkdir -p $home/.rustup/toolchains
      cp -r $rustInstall $home/.rustup/toolchains/$rustChannel-$toolchain;
      cp $rustupSettings $home/.rustup/settings.toml;

      # making nix' channels available so one can use nix-shell
      target=$out/nix/var/nix/profiles/per-user/root/channels
      mkdir -p $target
      cp -r $nixos $target/nixos
      cp -r $nixosUnstable $target/nixos-unstable

      # make everything immutable, even in VM
      chmod -R 550 $out
    '';
in {
  imports = [
    ../generalized.nix
    ../development.nix
    "${modulesPath}/image/repart.nix"
  ];

  image.repart = {
    inherit name;
    seed = "d2c6527b-d43b-49cd-b724-d4f1fdd771ec";

    # for the repartConfig key, see:
    # https://www.freedesktop.org/software/systemd/man/latest/repart.d.html
    partitions = {
      boot = {
        contents = let
          loader = system.boot.loader;
        in {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${loader.ukiFile}".source =
            "${system.build.uki}/${loader.ukiFile}";
          "/loader/loader.conf".source = pkgs.writeText "systemd-boot-config" ''
            editor false
            auto-firmware false
            timeout 0
          '';
        };
        repartConfig = {
          Type = "esp";
          Label = "BOOT";
          UUID = "47b77fd0-1cb6-42e0-8228-44611f0617b6";

          Format = "vfat";
          SizeMinBytes = "256M";
        };
      };
      root = {
        contents."/".source = rootTemplate;
        storePaths = [system.build.toplevel];
        # TODO: get rid of elusive-ssh and elusive-rsync and do it all via ssh config
        repartConfig = {
          Type = "root";
          Label = "ROOT";
          UUID = "276d46b6-2405-4c27-a28c-2fbefc6a97cd";

          Format = "ext4";
          SizeMinBytes = "75G";
        };
      };
    };
  };

  fileSystems = mapAttrs' (name: target:
    nameValuePair target (let
      cfg = config.image.repart.partitions.${name}.repartConfig;
    in {
      device = "/dev/disk/by-label/${cfg.Label}";
      fsType = cfg.Format;
      noCheck = true;
    })
  ) {
    root = "/";
    boot = "/boot";
  };

  boot = {
    kernelParams = ["console=ttyS0"];
    uki = { inherit name; };
  };

  generalized = {
    hostName = name;
    boot = null;
    baremetal = false;
    ssh = true;
    wayland = true;
  };

  users = {
    mutableUsers = false;
    users.multisn8.openssh.authorizedKeys.keyFiles = [
      ~/.ssh/id_to_elusive.pub
    ];
  };

  services = {
    getty.autologinUser = "multisn8";
    journald.extraConfig = ''
      SystemMaxUse=10M
    '';
  };

  security.sudo.enable = false;

  # pretty much just a stub so the shell deps are included in the image
  # and aren't cloned in each instance
  environment.shellInit = ''
    # ${toString shells}
  '';

  system.stateVersion = "24.05";
}
