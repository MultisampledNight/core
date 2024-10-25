Easy on-the-fly VMs.
Generate an image via `elusive-generate-base`,
start a VM with `elusive label`,
and you're good to go!

## How it works

### `elusive-generate-base`

Creates a compressed image with all configs and dev things copied into it
(around 11 GiB).
It is stored in the Nix store and
registered as GC root,
so the newest image will not be cleaned up by
`nixos-collect-garbage`
runs.

Behind the scenes, it uses NixOS' integration of [`systemd-repart`].

### `elusive`

Accepts one argument: the *label*.
While there can ever be only one elusive VM running at one point in time,
there can be different *instances* on disk.

If a label isn't associated with an instance,
a new clean one is created.
If it is associated with one,
its overlay is re-used.

The instances are keyed by the label.
Each instance is just an overlay,
which only stores the differences
to the base image,
so there's very little cost associated
with just quickly creating a new one
when you need to quickly test something in a VM!

### `elusive-clean-state`

Deletes all current instances on disk.
Note that this is *not* implied by `elusive-generate-base`:
`elusive-generate-base` runs through all existing instances
and rebases them onto the new image instead.

## Resources used

- Example guide: https://x86.lol/generic/2024/08/28/systemd-sysupdate.html
  - https://github.com/blitz/sysupdate-playground/blob/blog-post
- systemd-repart manual: https://www.freedesktop.org/software/systemd/man/latest/repart.d.html

[`systemd-repart`]: https://nixos.org/manual/nixos/stable/#sec-image-repart

