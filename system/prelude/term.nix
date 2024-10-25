{ config, pkgs, lib, ... }:

with builtins;
with lib;
rec {
  indent = strings.replicate 7 " ";

  # see https://en.wikipedia.org/wiki/ANSI_escape_code
  # why they are exactly here? good question, had no other place to put them
  # if anyone has an idea on how to escape this in nix, let me know
  esc = "";
  csi = params: op: esc + "[" + params + op;

  sgr = n: csi (toString n) "m";
  cha = n: csi (toString n) "G";
  reset = "${esc}(B" + (csi "" "m");

  fg = idx: sgr (30 + idx);

  query = "${fg 4}>${reset}";
  error = "${fg 1}!${reset}";
}
