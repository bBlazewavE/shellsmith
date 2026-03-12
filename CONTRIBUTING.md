# Contributing to Shellsmith

Thanks for your interest in contributing! This guide covers how to get set up and submit changes.

## Prerequisites

- macOS (aarch64 or x86_64)
- [Nix](https://nixos.org/) installed (run `./bootstrap.sh` if you don't have it)

## Getting Started

```bash
git clone https://github.com/bBlazewavE/shellsmith.git
cd shellsmith
nix develop    # enters dev shell with all tools
```

## Project Structure

```
flake.nix              # Nix devShell — all packages declared here
justfile               # Just recipes — setup, link, zshrc, npm, status, clean, update
bootstrap.sh           # One-time bootstrap (Xcode CLI + Nix)
shell/zshrc_block.zsh  # Shell config injected into ~/.zshrc
nvim/                  # Neovim config (init.lua + plugins)
tmux/tmux.conf         # tmux config
```

## Making Changes

### Adding a new package

1. Add it to the `packages` list in `flake.nix`
2. Run `nix develop` to verify it resolves
3. If it's an npm-only package, add it to the `npm` recipe in `justfile` instead

### Adding a new Just recipe

1. Add the recipe to `justfile`
2. Make it idempotent — safe to run multiple times without side effects
3. Use `#!/usr/bin/env bash` + `set -euo pipefail` for multi-line recipes
4. If it should run during initial setup, add it to the `setup` dependency list

### Modifying shell config

Edit `shell/zshrc_block.zsh`. The `just zshrc` recipe handles injecting it into `~/.zshrc` between markers.

### Modifying Neovim config

All Neovim config lives in `nvim/`. Plugins are managed by lazy.nvim and auto-install on first launch. Test changes by running `nvim` after editing.

## Submitting Changes

1. Fork the repo
2. Create a branch: `git checkout -b my-change`
3. Make your changes
4. Test: `nix develop --command just setup` and `just status`
5. Commit with a clear message describing what and why
6. Open a pull request against `main`

## Guidelines

- Keep recipes idempotent
- Don't add Homebrew dependencies — use Nix or npm
- Test on a clean `nix develop` shell before submitting
- One feature or fix per PR
- Update the README if your change affects the user-facing interface

## Reporting Issues

Open an issue at [github.com/bBlazewavE/shellsmith/issues](https://github.com/bBlazewavE/shellsmith/issues) with:
- What you expected
- What happened
- Output of `just status`
- macOS version (`sw_vers`)

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
