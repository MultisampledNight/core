{
  pkgs ? import <nixpkgs> {}
}: 

pkgs.mkShell {
  buildInputs = with pkgs; [
    jdk
    jdt-language-server
    google-java-format
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<java>"
  '';
}
