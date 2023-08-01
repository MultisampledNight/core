# configs but it's actually a [NixOS](https://nixos.org) configuration

Most configs in here can be used without NixOS though.

## What this contains

All of my configurations which would be needed to set up a new system and develop on it. That includes [Neovim], [Neovide], [Alacritty], [Sway], [i3] and more.

Where possible, I try to use open-source software. Notable exceptions to this include CUDA, [Obsidian] and Steam (and all applications installed through it). I try to move away from them, but sometimes it's simply not possible (yet).

Development is actually rarely done on the actual machine, but rather in VMs, which are collectively and individually called "elusive". See the [elusive README] for details.

[Neovim]: https://neovim.io/
[Neovide]: https://neovide.dev/
[Alacritty]: https://alacritty.org/
[Sway]: https://alacritty.org/
[i3]: https://i3wm.org/
[Obsidian]: https://obsidian.md/
[elusive README]: ./nixos/elusive/README.md

## Installation

**Note:** This will install **all** configs without asking. Did I mention that the scripts used are hardcoded to `/home/multisn8` as the home path for the time being? Yeah, this tells a lot about when it should be used by you — **never**, at least not under extensive change. Take these configs as reference, not as template. Examine where I went wrong in your opinion, and do it better.

### Systemwide (as in, NixOS itself)

First of all, you need a running NixOS installation. No, the live ISO doesn't suffice. Nor does it `nixos-enter`ed into the to-be-installed system. If you're just setting up a fresh NixOS instance on this machine, I recommend just going for a very basic bootloader-only config first which boots you to the Linux console and already has a `multisn8` user with `sudo` access. Possibly slight modification of the the default generated by `nixos-generate-config` already suffices for this.

Then for the actual fun. All system management stuff on my system is stored in `~/zukunftslosigkeit`, and by extension the configs are supposed to (as in, do not _have_ to, but _should_ be) be in `~/zukunftslosigkeit/configs`. In the toplevel directory are two neat scripts called `distribute_symlinks.py` and `readjust_perms.py`, the first one spreading symlinks to `/etc/nixos`, `~/.config/...` and the like to point into this repository, and the latter one adjusting the permissions properly to be changeable by `multisn8`.

Running `distribute_symlinks.py` backs up potentially previous files into `~/_archive/<timestamp>` before overwriting. You should also run `nixos-generate-config` afterwards to make sure your hardware config is also fitting.

All in all, that'd be this:

```console
mkdir -p ~/zukunftslosigkeit
cd ~/zukunftslosigkeit
git clone https://github.com/MultisampledNight/configs
cd configs
sudo ./distribute_symlinks.py
sudo ./readjust_perms.py
nixos-generate-config
```

However, this won't suffice. One final step remains. Actually creating a `configuration.nix` utilizing the modules provided by this repo. In specific, you likely want to include

- `generalized.nix` and set its options, which provides the base set of options almost all other modules refer to.
- possibly `development.nix` if you intend to do any kind of development on this machine.
- possibly a hardware-specific model like `portable.nix` or `desktop.nix` if this is a physical machine rather than a container or the like.

For example, you could take a look at [the elusive `configuration.nix`] which is a development VM, or this one which is (basically) the `configuration.nix` of one of my physical machines:

```nix
# vim: ts=2 sw=2 et

{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./generalized.nix
      ./desktop.nix
    ];

  generalized = {
    hostName = "no";
    wireless.wlan = true;
    externalInterface = "wlan0";
    ssd = true;
    ssh = true;
    xorg = true;
    wayland = true;
    profileGuided = true;
    videoDriver = "nvidia";

    forMulti = true;
  };

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
```

Afterwards, run `sudo nixos-rebuild boot && reboot`, and you're good to go!

## User-only (does not require root)

**Note:** Untested. At your own risk.

```console
mkdir -p ~/zukunftslosigkeit
cd ~/zukunftslosigkeit
git clone https://github.com/MultisampledNight/configs
cd configs
./distribute_symlinks.py --exclude-nixos
```

You'll need to get the Neovim plugins from somewhere else though then.
