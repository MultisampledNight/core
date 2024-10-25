{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    elixir
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<elixir>"
    export MIX_PATH="${pkgs.beam.packages.erlang.hex}/lib/erlang/lib/hex/ebin"
    export ERL_AFLAGS="-kernel shell_history enabled"
  '';
}
