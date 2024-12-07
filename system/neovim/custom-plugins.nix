# the nixpkgs manual suggests to have this to be generated automatically instead
# but I don't want to have all that out-of-bounds state management for the few plugins I maintain anyway
{ pkgs, lib, ... }:

let
  build = pkgs.vimUtils.buildVimPlugin;
in final: prev: {
  multisn8-colorschemes = build {
    name = "multisn8-colorschemes";
    version = "2023-07-14";
    src = pkgs.fetchFromGitHub {
      owner = "MultisampledNight";
      repo = "colorschemes";
      rev = "main";
      hash = "sha256-SYpWCPR2ORrfraMuvTRoQ4zE9FSFHTpbIh9G+vElzK8=";
    };
    meta.homepage = "https://github.com/MultisampledNight/colorschemes";
  };
  tree-climber-nvim = build {
    name = "tree-climber-nvim";
    version = "2022-10-14";
    src = pkgs.fetchFromGitHub {
      owner = "drybalka";
      repo = "tree-climber.nvim";
      rev = "9b0c8c8358f575f924008945c74fd4f40d814cd7";
      hash = "sha256-iivP8g8aSeEnS/dBcb0sg583ijzhWFA7w430xWPmjF0=";
    };
    meta.homepage = "https://github.com/drybalka/tree-climber.nvim";
  };
}
