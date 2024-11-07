{ pkgs ? import <nixos-unstable> {} }:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    typst
    typst-lsp
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<typst>"
  '';
}
