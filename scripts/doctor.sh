#!/usr/bin/env bash
set -euo pipefail

# Shellsmith Doctor – environment diagnostics
# Usage: just doctor

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
ok() {
    echo -e "${GREEN}ok${NC}: $1"
}

warn() {
    echo -e "${YELLOW}warn${NC}: $1"
}

error() {
    echo -e "${RED}error${NC}: $1"
}

check_version() {
    local name="$1" cmd="$2" pattern="$3"
    if ! command -v "$cmd" &>/dev/null; then
        error "$name not found in PATH"
        return 1
    fi
    local version=$($cmd 2>&1 | grep -oE "$pattern" | head -1 || echo "unknown")
    ok "$name $version"
    return 0
}

check_var_set() {
    local var="$1"
    if [[ -z "${!var:-}" ]]; then
        warn "$var not set"
        return 1
    fi
    ok "$var is set"
    return 0
}

check_disk_space() {
    local nix_store="${1:-.}"
    local available=$(df "$nix_store" | awk 'NR==2 {print $4}' || echo "unknown")
    if [[ "$available" == "unknown" ]]; then
        warn "couldn't determine disk space"
        return 1
    fi
    # Convert to GB
    local gb=$((available / 1024 / 1024))
    if [[ $gb -lt 5 ]]; then
        error "low disk space: ${gb}GB available (need 5GB+ for Nix)"
        return 1
    fi
    ok "disk space: ${gb}GB available"
    return 0
}

check_nerd_font() {
    # Try to detect a Nerd Font in common locations
    local nerd_font_dirs=(
        "$HOME/Library/Fonts"
        "/Library/Fonts"
        "/opt/homebrew/opt/font-*/share/fonts"
    )
    
    for dir in "${nerd_font_dirs[@]}"; do
        if ls "$dir"/*Nerd* 2>/dev/null | grep -q .; then
            ok "Nerd Font detected in $dir"
            return 0
        fi
    done
    
    warn "no Nerd Font detected (icons may look broken)"
    return 1
}

check_true_color() {
    if [[ -n "${COLORTERM:-}" ]] && [[ "$COLORTERM" == "truecolor" || "$COLORTERM" == "24bit" ]]; then
        ok "true color support detected"
        return 0
    fi
    
    if [[ "$TERM" == "xterm-256color" || "$TERM" == "screen-256color" ]]; then
        ok "256-color support detected (true color preferred)"
        return 0
    fi
    
    warn "TERM=$TERM (consider xterm-256color or enable true color in terminal)"
    return 1
}

check_daemon_running() {
    local daemon="$1"
    if pgrep -f "$daemon" &>/dev/null; then
        ok "$daemon is running"
        return 0
    else
        error "$daemon not running"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────

echo "=== Shellsmith Doctor ==="
echo ""

# Nix
echo "=== Nix ==="
check_version "nix" "nix" '[0-9]+\.[0-9]+\.[0-9]+'
if command -v nix &>/dev/null; then
    check_daemon_running "nix-daemon"
fi
echo ""

# Node
echo "=== Node.js ==="
if check_version "node" "node" 'v[0-9]+\.[0-9]+\.[0-9]+'; then
    version=$(node --version | sed 's/^v//')
    major="${version%%.*}"
    if [[ "$major" != "22" ]]; then
        warn "node major version is $major (expected 22)"
    fi
fi
echo ""

# Neovim
echo "=== Neovim ==="
if check_version "nvim" "nvim" 'v[0-9]+\.[0-9]+\.[0-9]+'; then
    if [[ -d "$HOME/.local/share/nvim" ]]; then
        ok "lazy.nvim data directory exists"
    else
        warn "lazy.nvim data directory not found (will be created on first nvim launch)"
    fi
fi
echo ""

# Zsh
echo "=== Shell ==="
check_version "zsh" "zsh" '[0-9]+\.[0-9]+([0-9]+)?'
check_version "tmux" "tmux" '[0-9]+\.[0-9]+'
echo ""

# Terminal
echo "=== Terminal ==="
check_true_color
check_nerd_font
echo ""

# Disk space
echo "=== Storage ==="
if [[ -d "$HOME/.local/share/nixpkgs" ]] || [[ -d "/nix/store" ]]; then
    check_disk_space "/nix/store"
else
    warn "Nix store not found (likely not in nix develop shell)"
fi
echo ""

# API keys
echo "=== API Keys ==="
check_var_set "ANTHROPIC_API_KEY" || true
if ! check_var_set "ANTHROPIC_API_KEY" 2>&1 | grep -q "ok"; then
    :
fi

# Check for alternative key sources
if command -v claude &>/dev/null && claude whoami &>/dev/null 2>&1; then
    ok "claude CLI authenticated"
fi
echo ""

# Symlinks
echo "=== Config Symlinks ==="
if [[ -L "$HOME/.config/nvim" ]]; then
    ok "~/.config/nvim is symlinked"
else
    warn "~/.config/nvim is not symlinked (run: just setup)"
fi

if [[ -L "$HOME/.tmux.conf" ]]; then
    ok "~/.tmux.conf is symlinked"
else
    warn "~/.tmux.conf is not symlinked (run: just setup)"
fi
echo ""

# Shell integration
echo "=== Shell Integration ==="
if grep -qF "# >>> shellsmith >>>" "$HOME/.zshrc" 2>/dev/null; then
    ok "shellsmith block in ~/.zshrc"
else
    warn "shellsmith block not found in ~/.zshrc (run: just setup)"
fi

if grep -qF "eval \"\$(fzf --zsh)\"" "$HOME/.zshrc" 2>/dev/null; then
    ok "fzf integration found"
elif grep -qF "eval" "$HOME/.zshrc" &>/dev/null; then
    warn "fzf integration not found (keybindings may not work)"
fi
echo ""

echo "=== Summary ==="
echo "Run 'just setup' to apply any missing configurations."
