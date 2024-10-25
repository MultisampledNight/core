{ pkgs ? import <nixos-unstable> {} }:

let
  python3Ext = pkgs.python3.withPackages (ps: [
    ps.ipython
  ]);
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3Ext black
    ruff-lsp
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<python>"
  '';
}
