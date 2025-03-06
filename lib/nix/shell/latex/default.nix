{ pkgs ? import <nixpkgs> { } }:

let
  latexWithTikz = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-basic pgf standalone german babel;
  });
in pkgs.mkShell { buildInputs = with pkgs; [ latexWithTikz texlab ]; }
