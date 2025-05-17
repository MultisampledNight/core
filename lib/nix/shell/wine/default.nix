{
  pkgs ? import <nixpkgs> { },
}:

with pkgs.lib;
pkgs.mkShell {
  buildInputs = with pkgs; [ wineWow64Packages.stagingFull ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<wine>"
  '';
}
