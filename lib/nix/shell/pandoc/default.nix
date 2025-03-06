{
  pkgs ? import <nixos-unstable> { },
}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [ pandoc ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<pandoc>"
  '';
}
