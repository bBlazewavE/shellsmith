#!/usr/bin/env bash
set -euo pipefail

# Shellsmith – one-time bootstrap for a fresh Mac
# Installs Xcode CLI tools and Nix, then hands off to `nix develop` + `just`

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: this script only supports macOS" >&2
  exit 1
fi
echo "macOS $(sw_vers -productVersion) detected"

# Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press Enter after the Xcode installer finishes."
  read -r
else
  echo "ok: Xcode CLI tools"
fi

# Nix (via Determinate Systems installer)
if ! command -v nix &>/dev/null; then
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix | sh -s -- install
  echo "Open a new terminal, then run:"
  echo "  cd $(pwd) && nix develop --command just setup"
else
  echo "ok: Nix already installed"
  echo ""
  echo "Ready! Run:"
  echo "  nix develop --command just setup"
fi
