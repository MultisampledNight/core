{
  config,
  pkgs,
  lib,
  ...
}@args:

with lib;
with import ../prelude args;
{
  config = {
    logind = {
      lidSwitchExternalPower = "ignore";
      lidSwitch = "ignore";
      extraConfig = ''
        HandleSuspendKey=ignore
      '';
    };
  };
}
