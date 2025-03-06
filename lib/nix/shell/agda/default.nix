{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell rec { buildInputs = with pkgs; [ agda agda-pkg ]; }
