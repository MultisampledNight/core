# Commonly used utilities.
#
# Use this by importing it directly but forwarding your module arguments.
# Effectively, if your module is `a`,
# then you probably want to write something akin to:
#
# ```nix
# { config, pkgs, ... } @ args:
#
# with import ./prelude args;
# a
# ```

{
  config,
  pkgs,
  lib,
  ...
}@args:

with lib;
with builtins;
rec {
  zero = sub: /home/multisn8/zero/${sub};
  core = sub: zero /core/${sub};

  term = import ./term.nix (args // { inherit core; });

  unstable = pkgs.unstable;
  custom = pkgs.custom;

  # Shorthand for generalized's configuration, usually done by the end-user.
  cfg = config.generalized;

  machine = rec {
    # Which color to use for prompts and the works.
    accent = mod entropy 15;
    # Some random number that's the same per host.
    entropy = lib.fromHexString (builtins.substring 0 8 (builtins.hashString "sha256" cfg.hostName));
  };

  mod = mag: rem: mag - (mag / rem) * rem;

  # Flattens the given list twice.
  # 1. The first level is flattened unconditionally.
  #    It is thought for `with ...;` statements.
  # 2. The second level needs to be a list with
  #    the first element being a boolean and
  #    the second element being another list.
  #    The list is only included iff the boolean is true.
  #
  # An example: unite [
  #   [
  #     [true ["meow" "awawa" "mrrp"]
  #     [false ["nyoom"]]
  #   ]
  #   [
  #     [true ["owo"]]]
  #   ]
  # ]
  # => ["meow" "awawa" "mrrp" "owo"]
  unite = toplevel: concatLists (concatMap tail (filter head (concatLists toplevel)));

  # Maps both keys and values of an attribute set, but each only individually.
  mapKv = keyOp: valueOp: mapAttrs' (key: value: nameValuePair (keyOp key) (valueOp value));
  mapKey = keyOp: mapKv keyOp (v: v);
  mapValue = valueOp: mapKv (k: k) valueOp;

  # Is `single` in the given list?
  contains = single: any (item: item == single);

  # Converts a list to an attribute set
  # with every value being set to `null`.
  listToNames =
    list:
    listToAttrs (
      map (ele: {
        name = ele;
        value = null;
      }) list
    );

  # Takes a list of strings and an attribute set,
  # filters the attribute set for all keys that are in the list.
  narrow = list: set: intersectAttrs (listToNames list) set;

  # Take value `lookup` for each key in `keys`,
  # joining the results in a list.
  # If a key is not in `lookup`, it'll have no effect on the joined list.
  select = lookup: keys: concatMap (key: lookup.${key} or [ ]) keys;

  # Fetches the given nixpkgs revision and returns its import.
  # You can directly access the values to get a package!
  nixpkgsFromCommit =
    {
      rev,
      hash,
      opts ? { },
      owner ? "nixos",
    }:
    let
      tree = pkgs.fetchzip {
        name = "nixpkgs-${rev}";
        url = "https://github.com/${owner}/nixpkgs/archive/${rev}.tar.gz";
        hash = hash;
      };
    in
    import tree opts;

  # Overrides a Rust package's source, including the cargo dep hash.
  overrideRust = prevPkg: { src, cargoHash }: prevPkg.overrideAttrs (_: rec {
    inherit src;
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = cargoHash;
    };
  });

  # Fetches the nixpkgs PR with the given number and
  # returns an overlay
  # which overrides the given package names,
  # taking them from the PR instead.
  #
  # `packages` has to be a list of strings.
  takeFromPr =
    {
      pr,
      hash,
      packages,
    }:
    (
      _: _:
      narrow packages (nixpkgsFromCommit {
        rev = "pull/${toString pr}/head";
        inherit hash;
      })
    );

  toSudoers =
    dense:
    concatStringsSep "\n" (
      mapAttrsToList (
        name: value:
        "Defaults "
        + (
          if (isBool value) then
            (optionalString (!value) "!") + name
          else if (isString value) then
            ''${name}="${value}"''
          else
            "${name}=${toString value}"
        )
      ) dense
    );

  # List of all used video drivers.
  allVideoDrivers = unique (
    let
      unsorted =
        if cfg.video.driver == null then
          [ ]
        else if (isAttrs cfg.video.driver) then
          (attrValues cfg.video.driver)
        else
          singleton cfg.video.driver;

      pref = cfg.video.prefer;
    in
    if pref == null then unsorted else [ pref ] ++ (remove pref unsorted)
  );

  # Is there at least one Nvidia GPU on this system?
  hasNv = contains "nvidia" allVideoDrivers;

  # Shorthand for `select ... allVideoDrivers`.
  selectForDrivers = lookup: select lookup allVideoDrivers;
}
