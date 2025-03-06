{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    SDL2
    SDL2_gfx
    SDL2_image
    SDL2_ttf
    SDL2_mixer
    SDL2_sound
    SDL2_net
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<sdl>"
  '';
}
