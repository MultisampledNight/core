# Shells

In here are `default.nix`es intended for `nix-shell`, usually one for each language or common environment. There's a couple things to note though.

## `~/.zshrc`

It performs a few QoL things worth noting.

- `NIX_PATH` is set to additionally include this directory.
    - This makes it possible to launch any shell here simply by putting the folder name in angle brackets (and escaping them properly for zsh), as in `nix-shell '<typst>'` for a [typst] shell.
    - Of course this also implies that shells shouldn't be named anything funny, like `nixpkgs` or `nixos`. They'll be shadowed by the earlier `NIX_PATH` entries anyway.
- It shadows the `nix-shell` command to make it launch zsh instead of bash.
- It also additionally provides a `shell` command, which allows quick nesting of multiple shells and doesn't require all those tedious angle brackets and quotes.
    - For example, a quick shell with [Rust], [Python] and [typst] is as easy as `shell rust python typst`.


## Interaction with `direnv`

The shells are not supposed to be leaked to the outside world, but can be useful for local development. Often it's already clear that one project will _always_ require that one shell to be loaded in order to meaningfully develop it. To facilitate this, `direnv` is loaded in `~/.zshrc`.

An example `.envrc` for a typical [Rust] project **for local development** might be this one:

```sh
use nix '<rust>'
```

Be aware of in which context you're operating when running `direnv allow`. Think especially twice about your host machine rather than on a secured VM.

[Rust]: https://www.rust-lang.org/
[Python]: https://www.python.org/
[typst]: https://typst.app/
