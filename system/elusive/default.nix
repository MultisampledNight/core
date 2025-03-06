let
  pkgs = import <nixos> {
    overlays = [ (final: prev: { unstable = import <nixos-unstable> { }; }) ];
  };
  name = "elusive";

  realize = configuration: (pkgs.nixos [ configuration ]).image;

  built = realize (import ./configuration.nix { inherit name; });
  raw = "${built}/${name}.raw";
  target = "$out/base.qcow2";
in
pkgs.runCommand "elusive-image" { buildInputs = with pkgs; [ qemu ]; } ''
  mkdir -p $out
  qemu-img convert \
    -c -o compression_type=zstd \
    -f raw -O qcow2 \
    ${raw} ${target}
''
