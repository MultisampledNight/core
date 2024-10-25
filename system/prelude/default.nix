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

{ config, pkgs, lib, ... } @ args:

with lib;
rec {
  zero = sub: /home/multisn8/zero/${sub};
  core = sub: zero /core/${sub};

  term = import ./term.nix (args // { inherit core; });
  unstable = pkgs.unstable;
  custom = pkgs.custom;

  # Shorthand for generalized's configuration, usually done by the end-user.
  cfg = config.generalized;

  # Returns the given `value` if `cond`, otherwise an empty list.
  condList = cond: value:
    if cond
    then value
    else [];

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
  unite = toplevel: concatLists (
    concatMap tail
    (filter head (concatLists toplevel))
  );

  # Maps both keys and values of an attribute set, but each only individually.
  mapKv = keyOp: valueOp: mapAttrs'
    (key: value: nameValuePair
      (keyOp key)
      (valueOp value)
    );
  mapKey = keyOp: mapKv keyOp (v: v);
  mapValue = valueOp: mapKv (k: k) valueOp;

  nixpkgsFromCommit = { rev, hash, opts ? {} }:
    let
      tree = pkgs.fetchzip {
        name = "nixpkgs-${rev}";
        url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
        hash = hash;
      };
    in
      import tree opts;

  toSudoers = dense: concatStringsSep "\n" (
    mapAttrsToList (name: value: "Defaults " + (
      if (isBool value) then
        (optionalString (!value) "!") + name
      else if (isString value) then
        "${name}=\"${value}\""
      else
        "${name}=${toString value}"
    ))
    dense
  );
}
