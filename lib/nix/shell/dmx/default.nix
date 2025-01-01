{ pkgs ? import <nixpkgs> {} }:

with pkgs.lib;
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    libftdi
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<dmx>"
    export LD_LIBRARY_PATH+=":${builtins.toString (makeLibraryPath buildInputs)}";
  '';
}
