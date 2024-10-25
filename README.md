# You are approaching CORE

Or in other words, welcome to my configs!
This contains everything I personally use and need
in order to use a new machine.

## Structure

### [`bootstrap`](./bootstrap)

Helpers for setting up a system ready for usage.

The main script here is `distribute_symlinks`.
It "spreads" symlinks across the system targeting e.g. `config`.

### [`config`](./config)

What you're probably here for.

Program-specific configuration.

### [`gfx`](./gfx)

Graphics and accompanying art.

Mostly managed with Git LFS in order to avoid blowing up repo size.

### [`lib`](./lib)

Nix shells, resources and other things that are usually not touched directly.

Protip: You can launch any shell in `lib/nix/shell`
using the `shell` function as defined in this repo's `zshrc`!

### [`path`](./path)

Things that should be on `$PATH`,
i.e. that should be runnable without specifying their full path.

While they are categorized into folders here,
all folders in there (recursively) end up flattened on `$PATH`.
The categories are:

#### [`auto`](./path/auto)

Anything that is called by "automations",
for example window manager hotkeys or shell helpers.

You usually don't need to call them directly on the terminal.

#### [`elusive`](./path/elusive)

Facilitate interaction with [elusive],
see [`system/elusive`](./system/elusive) for details.

#### [`lib`](./path/lib)

Don't perform any meaningful work on their own.
Usually expose some interesting variables and functions.

For example, [`path/lib/_initenv`](./path/lib/_initenv)
takes care of configuring `$PATH` such that everything
in here can be found,
but needs to be `source`d from another shell for that.

#### [`maintain`](./path/maintain)

System maintenance commands.

Currently just NixOS generation management.

#### [`script`](./path/script)

Cute small scripts that make frequent tasks easier.

For example, [`path/script/clean`](./path/script/clean)
cleans the filesystem of build directories and redundant PDFs.

#### [`wrapper`](./path/wrapper)

Pretend to be a program.
Maybe even are that program just with some spice added!

### [`system`](./system)

Utilities for building a [NixOS] configuration.

While you don't have to use it in order to use the other elements here,
it takes care of setting up all services,
installing all programs and
the works.

## Installation

> [!NOTE]
> This will install **all** configs without asking,
> overwriting previous configs with the same name.
> Did I mention that the scripts used are hardcoded to `/home/multisn8`
> as the home path for the time being?
> Yeah, this tells a lot about when it should be used by you — **never**,
> at least not without extensive change.
> Take these configs as reference, not as template.
> Examine where I went wrong in your opinion, and do it better.

### Systemwide (as in, NixOS itself)

A script automating all this may be provided in future.

1. Install NixOS onto disk
2. Set up a `multisn8` user
4. Set up the `nixos-unstable` channel
5. Update all channels
3. Clone this repository to `~/zero/core`
6. Run `bootstrap/distribute_symlinks.py`
7. Symlink `$(pwd)/system` to `/etc/nixos`
8. Run `nixos-generate-config`
9. Adjust `configuration.nix` to use modules from `generalized` as desired
10. Run `sudo nixos-rebuild boot && reboot`

Example `configuration.nix`:

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
    audio = true;
    profileGuided = true;
    videoDriver = "nvidia";
  };

  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
```

### User-only (does not require root)

**Note:** Untested. At your own risk.

```console
mkdir -p ~/zero
git clone https://github.com/MultisampledNight/core ~/zero/core
cd ~/zero/core
./bootstrap/distribute_symlinks.py --only-user --user $USER
```

You'll need to get the Neovim plugins from somewhere else though then.

## Less important things

### On open-sourceness

Open-source is awesome.
If something doesn't work,
I can try to look into it
and possibly even help fixing it.

At some point I'd like for everything in my config
to be fully open-source.
The exceptions stopping that at the moment are:

- [CUDA]: I still have an Nvidia GPU, and in order to use it meaningfully,
  I unfortunately need CUDA.
  It starts breaking though, maybe I'll get something else soon.
- Steam (and all applications installed through it): Most games aren't open-source.

## Terminology

### elusive

The codename for the system I use for constructing VMs!
Check the [elusive] README for details.

### zero

Usually the folder `~/zero`.
Where all of the stuff that is made for me stores stuff for me.
Imagine it like a "system" folder that contains information for the system
itself.

I'm not following the XDG spec here
to avoid having other software pollute my state.
However, you're free to ask if a mechanism could be made standalone —
I'm very much interested in keeping software
which is used by others
standards-compilant.

#### Why?

`zero` starts with the letter `z`,
so it's always listed at the bottom
of descendingly alphabetically sorted lists.

It also serves semantically well for being
the identity element of addition
of the real numbers.
After all, this folder is what makes this system *my* system.
It is the basis I build my reality on.

(Fun fact: `zero` used to be named `zukunftslosigkeit`,
German for "lack of future".
That was both too long and too depressing.)

### core

Usually the folder `~/zero/core`.
The defining heart of my system.
It is this very repository you're looking at and
configures everything in and around my system.

#### Why?

This is an [Undertale] reference.
I refuse to elaborate further.
Please do go play Undertale if you haven't yet.
It is an awesome game.
It might reveal a lot about you.


[NixOS]: https://nixos.org/
[CUDA]: https://developer.nvidia.com/cuda-zone
[elusive]: ./system/elusive
[Undertale]: https://undertale.com/
