{
  pkgs ? import <nixpkgs> { },
  extraPkgs ? [ ],
}:

pkgs.mkShell rec {
  buildInputs =
    with pkgs;
    [
      rustup
      cargo-audit
      cargo-crev
      cargo-dist
      cargo-expand
      cargo-flamegraph
      cargo-geiger
      cargo-make
      cargo-nextest
      cargo-pgo
      cargo-vet
      cargo-watch
      cargo-wizard
      typos
      just
      fd
      sea-orm-cli
      sqlx-cli

      valgrind
      gdb
      lldb
      rr
      clang
      llvmPackages_20.libclang
      bolt_20
      libgcc.lib
      mold
      elfkickers
      openssl
      pkg-config
      cmake
      wasm-pack
      evcxr
      tokei
      libxkbcommon
      wayland
      xorg.libX11
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXi
      alsa-lib
      fontconfig
      freetype

      shaderc
      directx-shader-compiler
      ocl-icd
      libGL
      vulkan-headers
      vulkan-loader
      vulkan-tools
      vulkan-tools-lunarg
      vulkan-validation-layers
      vulkan-extension-layer
      monado
      openxr-loader
      openxr-loader.dev

      librealsense-gui
      opencv

      z3

      mdbook
      mdbook-linkcheck
      mdbook-pagetoc

      python3
      renderdoc
      gnuplot
    ]
    ++ extraPkgs;

  CARGO_BUILD_RUSTDOCFLAGS = "--default-theme=ayu";
  RUSTC_VERSION = pkgs.lib.strings.removeSuffix "\n" (pkgs.lib.readFile ./rust-toolchain);
  LIBCLANG_PATH = pkgs.lib.makeLibraryPath [ pkgs.llvmPackages.libclang.lib ];

  BINDGEN_EXTRA_CLANG_ARGS = with pkgs.llvmPackages_latest.libclang; [
    ''-I"${lib}/lib/clang/${version}"''
  ];

  shellHook = ''
    export SHELL_NAME="''${SHELL_NAME:+$SHELL_NAME/}<rust>"
    export PATH="$PATH:''${CARGO_HOME:-$HOME/.cargo}/bin"
    export PATH="$PATH:''${RUSTUP_HOME:-$HOME/.rustup/toolchains/$RUSTC_VERSION-x86_64-unknown-linux/bin}"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${builtins.toString (pkgs.lib.makeLibraryPath buildInputs)}";

    rustup default $RUSTC_VERSION
    rustup install stable
    rustup component add \
      rustfmt \
      clippy \
      rust-src \
      rust-analyzer \
      rustc-codegen-cranelift \
      llvm-tools
  '';
}
