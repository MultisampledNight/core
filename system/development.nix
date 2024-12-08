{ config, pkgs, lib, ... } @ args:

with lib;
with import ./prelude args;
let
  customVimPlugins = pkgs.unstable.vimPlugins.extend (
    pkgs.unstable.callPackage ./neovim/custom-plugins.nix {}
  );
  cudatk = pkgs.unstable.cudatoolkit;
  nvidia = config.boot.kernelPackages.nvidia_x11;
in {
  documentation = {
    enable = true;
    dev.enable = true;
    man.generateCaches = true;
  };

  environment = {
    systemPackages = unite [
      (with pkgs; [
        [true [
          delta
          inotify-tools geoipWithDatabase
          sshfs

          # languages
          black 
          llvmPackages_latest.llvm llvmPackages_latest.bintools llvmPackages_latest.lld
          clang sccache

          direnv
        ]]
        [cfg.graphical [
          ghidra sqlitebrowser
          jetbrains.idea-community
          jetbrains.pycharm-community
        ]]
        [(cfg.videoDriver == "nvidia") [
          cudatk
          nvidia
        ]]
      ])
      (with unstable; [
        [true [
          typst

          tinymist
          typos-lsp
          nil
        ]]
        [cfg.graphical [
          godot_4
          neovide
        ]]
      ])
    ];

    sessionVariables = {
      VK_ICD_FILENAMES =
        # hacky but who cares, it's semi-ensured to be there through hardware.opengl.extraPackages anyway
        condList (cfg.videoDriver != null)
          [
            "/run/opengl-driver/share/vulkan/icd.d/${cfg.videoDriver}_icd.x86_64.json"
            "/run/opengl-driver-32/share/vulkan/icd.d/${cfg.videoDriver}_icd.i686.json"
          ];
      NEOVIDE_FORK = "1";
    }
    // (if cfg.videoDriver == "nvidia" then {
      # both required for blender
      CUDA_PATH = "${cudatk}";
      CYCLES_CUDA_EXTRA_CFLAGS = concatStringsSep " " [
        "-I${cudatk}/targets/x86_64-linux/include"
        "-I${nvidia}/lib"
      ];
    } else {})
    // (if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
    } else {});

    extraInit = (if cfg.videoDriver == "nvidia" && cfg.xorg then ''
      export LD_LIBRARY_PATH="${config.hardware.nvidia.package}/lib:$LD_LIBRARY_PATH"
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
      defaultEditor = true;
      package = pkgs.unstable.neovim-unwrapped;
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
            cmp-vsnip vim-vsnip
            nvim-lspconfig trouble-nvim plenary-nvim
            telescope-nvim telescope-ui-select-nvim
            nvim-dap nvim-dap-ui

            (nvim-treesitter.withPlugins (parsers: with parsers; [
              arduino c cpp c_sharp elixir gdscript javascript julia haskell
              ocaml objc lua python r rust swift typescript
              glsl hlsl wgsl
              cuda
              bash
              gitignore gitcommit git_rebase git_config gitattributes
              vim nix proto godot_resource
              kdl ini toml yaml json json5 xml
              css html
              sql dot mermaid
              latex bibtex markdown typst
              diff query vimdoc
              agda
            ]))
            nvim-treesitter-context
            nvim-ts-autotag
            tree-climber-nvim
            rainbow-delimiters-nvim

            vim-polyglot vim-signify
          ];
          opt = [];
        };
      };
    };

    git.lfs.enable = true;
  };

  fonts = mkIf cfg.graphical {
    packages = with pkgs; [
      hack-font
      roboto roboto-mono
      ibm-plex
      manrope
      source-code-pro
      (nerdfonts.override { fonts = ["FiraCode" "JetBrainsMono"]; })
      departure-mono

      atkinson-hyperlegible
      montserrat
      noto-fonts
      cantarell-fonts
      inter
      overpass
      ttf_bitstream_vera
      ubuntu_font_family
      source-han-sans

      libertinus
    ];

    fontDir.enable = true;
    # this adds a few commonly expected fonts like liberation...
    enableDefaultPackages = true;

    fontconfig = let
      # in points
      size = 14;
    in {
      hinting.style = "slight";

      # ...while this one sets the actually in-place default fonts
      defaultFonts = {
        serif = ["Libertinus Serif"];
        sansSerif = ["IBM Plex Sans"];
        monospace = ["JetBrainsMono NL NF Light"];
      };

      # see fonts-conf(5), especially on the <EDIT ...> part
      localConf = ''
        <?xml version='1.0'?>
        <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
        <fontconfig>
        <match>
          <edit name="size" binding="strong">
            <double>${toString size}</double>
          </edit>
        </match>
        </fontconfig>
      '';
    };
  };
}
