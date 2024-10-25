# vim: ts=2 sw=2 et
{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./generalized.nix
      ./portable.nix
    ];

  generalized = {
    hostName = "destined";
    layout = "bone";
    cpuVendor = "intel";
    wireless = {
      wlan = true;
      bluetooth = true;
    };
    externalInterface = "wlan0";
    ssd = true;
    ssh = true;
    wayland = true;
    videoDriver = "intel";
    hidpi = true;
    audio = true;
    profileGuided = false;

    multimedia = true;
    gaming = true;
  };

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = lib.mkForce true;
      efiSupport = true;
      useOSProber = true; # detect ubuntu

      device = "/dev/nvme0n1";

      font = "${pkgs.ibm-plex}/share/fonts/opentype/IBMPlexMono-Regular.otf";
      fontSize = 32;
      theme = "${pkgs.libsForQt5.breeze-grub}/grub/themes/breeze";
    };
  };

  users = {
    motd = "Everyone's destiny is to find their destiny. Or to execute it.";

    users.multisn8.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkcCO74M9kP6gRlyTqaWInfwmScvQBVi0FPLAH2BYWG multisn8@overloaded"
    ];
  };

  networking = {
    hosts = {
      "192.168.1.110" = ["overloaded"];
    };
    firewall.interfaces."enp0s13f0u2u2u1".allowedUDPPorts = [9875 46020];
  };

  nix = {
    distributedBuilds = false;
    buildMachines = [
      {
        hostName = "lifted";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        sshUser = "multisn8";
        sshKey = "/home/multisn8/.ssh/id_to_overloaded";

        maxJobs = 8;
        speedFactor = 2;
      }
    ];
  };

  environment.systemPackages = with pkgs; [macchanger];

  services = {
    printing.drivers = with pkgs; [
      gutenprint
      gutenprintBin
      cnijfilter2
      hplip
    ];
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
  };

  programs.firefox.policies.Permissions.Microphone.Allow = [
    "https://discord.com/"
  ];

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
