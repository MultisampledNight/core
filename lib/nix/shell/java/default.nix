{
  pkgs ? import <nixpkgs> {}
}: 

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    jdk
    java-language-server
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<java>"
  '';
}
