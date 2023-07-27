{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
  pkgs-unstable = import <nixos-unstable> {};

  neovideSmooth = pkgs.callPackage ./neovide/default.nix {};
  customVimPlugins = pkgs-unstable.vimPlugins.extend (
    pkgs-unstable.callPackage ./neovim/custom-plugins.nix {}
  );
  latexWithTikz = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-basic pgf standalone german babel;
  });

in {
  documentation = {
    enable = true;
    man.generateCaches = true;
  };

  environment = {
    systemPackages = with pkgs;
    [
      python3 black godot_4 delta
      inotify-tools geoipWithDatabase
      sshfs

      # languages (for Rust it's probably better to directly use a shell.nix instead)
      python3 black
      llvmPackages_latest.llvm llvmPackages_latest.bintools llvmPackages_latest.lld
      clang sccache latexWithTikz texlab

      direnv
    ]
    ++ (if cfg.graphical then [
      ghidra sqlitebrowser neovideSmooth
    ] else [])
    ++ (if cfg.forTheGeneralPublic then [
      jetbrains.pycharm-community
      R nodejs openjdk
    ] else [])
    ++ (if cfg.videoDriver == "nvidia" then [
      cudatoolkit
    ] else []);

    sessionVariables = {
      VK_ICD_FILENAMES =
        if cfg.videoDriver == "intel"
        # hacky but who cares, it's semi-ensured to be there through hardware.opengl.extraPackages anyway
        then "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"
        else "";
    }
    // (if cfg.videoDriver == "nvidia" then {
      # both required for blender
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CYCLES_CUDA_EXTRA_CFLAGS = "-I${pkgs.cudatoolkit}/targets/x86_64-linux/include";
    } else {})
    // (if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    } else {});

    extraInit = (if cfg.videoDriver == "nvidia" && cfg.xorg then ''
      export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
    '' else "")
    + (if cfg.xorg then ''
      # is X even running yet?
      if [[ -n $DISPLAY ]]; then
        # key repeat delay + rate
        xset r rate 260 60
        # turn off the bell sound
        xset b off
      fi
    '' else "");
  };

  programs = {
    neovim = {
      defaultEditor = !cfg.forTheGeneralPublic;
      package = pkgs.neovim-nightly-unwrapped;
      withNodeJs = true;
      withRuby = false;

      configure = {
        customRC = ''
          silent! source ~/.config/nvim/init.vim
        '';

        packages.plugins = with customVimPlugins; {
          start = [
            multisn8-colorschemes

            nvim-cmp cmp-path cmp-cmdline cmp-nvim-lsp
            nvim-lspconfig trouble-nvim plenary-nvim
            telescope-nvim telescope-ui-select-nvim
            (nvim-treesitter.withPlugins (parsers: with parsers; [
              arduino c cpp c_sharp elixir gdscript javascript julia haskell
              ocaml objc lua python r rust swift typescript
              glsl hlsl wgsl
              cuda
              bash
              gitignore gitcommit git_rebase git_config gitattributes
              vim nix proto godot_resource
              kdl ini toml yaml json json5
              css html
              sql dot mermaid latex bibtex markdown
              diff query vimdoc
            ]))
            playground # nvim-treesitter's playground
            vim-polyglot vim-signify
          ];
          opt = [];
        };
      };
    };

    git.lfs = {
      enable = true;
    };
  };

  fonts = mkIf cfg.graphical {
    fonts = with pkgs; [
      hack-font
      roboto roboto-mono
      ibm-plex
      manrope
      source-code-pro

      cantarell-fonts
      inter
      overpass
      ttf_bitstream_vera
      ubuntu_font_family
    ];

    fontDir.enable = true;
    # this adds a few commonly expected fonts like liberation...
    enableDefaultFonts = true;

    fontconfig = {
      hinting.style = "hintslight";

      # ...while this one sets the actually in-place default fonts
      defaultFonts = {
        serif = ["IBM Plex Serif"];
        sansSerif = ["IBM Plex Sans"];
        monospace = ["IBM Plex Mono"];
      };
    };
  };

  i18n.inputMethod = mkIf cfg.graphical {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [hangul];
  };

  nixpkgs.overlays = [
    (final: prev: {
      neovim-nightly-unwrapped = prev.neovim-unwrapped.overrideAttrs {
        version = "0.10.0-nightly";
        src = pkgs.fetchFromGitHub {
          owner = "neovim";
          repo = "neovim";
          rev = "14d047ad2f448885de39966d1963f15d3fa21089";
          hash = "sha256-2JHBvDWMKd3brUwzU5NMc2cqrrqyoXZ3p8AFN82MNPI=";
        };
      };
    })
  ];
}