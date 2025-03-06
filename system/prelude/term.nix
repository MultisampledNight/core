{ pkgs, core, ... }:

with pkgs.lib;
let
  table = fromTOML (readFile (core /lib/terminal.toml));
  code = rec {
    # see https://en.wikipedia.org/wiki/ANSI_escape_code
    # why they are exactly here? good question, had no other place to put them
    esc = table.codes.esc;
    csi = params: op: esc + "[" + params + op;

    sgr = n: csi (toString n) "m";
    cha = n: csi (toString n) "G";

    reset = "${esc}(B" + (csi "" "m");
    fg = idx: sgr (30 + idx);
  };
in
{
  indent = strings.replicate table.indent.base " ";
}
// code
// (mapAttrs (_: cfg: (code.fg cfg.color) + cfg.symbol + code.reset) table.messages)
