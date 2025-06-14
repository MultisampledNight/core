{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell rec {
  buildInputs = with pkgs; [
    bcftools
    bedtools
    bwa
    fastp
    snpeff
    pangolin
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<bioinfo>"
  '';
}
