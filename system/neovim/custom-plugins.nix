# the nixpkgs manual suggests to have this to be generated automatically instead
# but I don't want to have all that out-of-bounds state management for the few plugins I maintain anyway
{ pkgs, lib, ... }:

let build = pkgs.vimUtils.buildVimPlugin;
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
}
