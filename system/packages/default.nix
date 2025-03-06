{ pkgs ? import <nixpkgs> { } }:

with pkgs.lib;
let
  packageNames =
    filterAttrs (_: kind: kind == "directory") (builtins.readDir ./.);
in mapAttrs (name: _: pkgs.callPackage ./${name} { }) packageNames
