{ pkgs ? import <nixpkgs> {
  config = {
    allowUnfree = true;
  };
} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    nmap hashcash openssl
    binwalk
    ngrok

    intelmetool coreboot-utils
    wireshark
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<sec>"
  '';
}
