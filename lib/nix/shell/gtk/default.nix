{ pkgs ? import <nixpkgs> { } }:
pkgs.callPackage ../rust/default.nix {
  extraPkgs = with pkgs; [ glib gtk4 gdk-pixbuf cairo graphene pango ];
}
