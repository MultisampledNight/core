{ pkgs ? import <nixos-unstable> { } }:

pkgs.mkShell { buildInputs = with pkgs; [ pmbootstrap ]; }
