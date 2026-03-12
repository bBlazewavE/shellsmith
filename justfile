# Shellsmith – AI dev workflow
# Usage: nix develop --command just setup

set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
timestamp := `date +%Y%m%d-%H%M%S`

# Default recipe: run full setup
setup: link zshrc ralph npm
    @echo ""
    @echo "shellsmith: setup complete"
    @echo "  Run: source ~/.zshrc"

# Symlink config files (with backup)
link:
    #!/usr/bin/env bash
    set -euo pipefail
    TIMESTAMP="{{ timestamp }}"

    backup_and_link() {
        local source="$1" target="$2"
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            echo "  ok: $target"
            return
        fi
        if [[ -e "$target" ]] || [[ -L "$target" ]]; then
            local backup="${target}.backup.${TIMESTAMP}"
            mv "$target" "$backup"
            echo "  backup: $target → $backup"
        fi
        mkdir -p "$(dirname "$target")"
        ln -sf "$source" "$target"
        echo "  linked: $source → $target"
    }

    backup_and_link "{{ root }}/nvim" "$HOME/.config/nvim"
    backup_and_link "{{ root }}/tmux/tmux.conf" "$HOME/.tmux.conf"

# Inject shell config into ~/.zshrc between markers
zshrc:
    #!/usr/bin/env bash
    set -euo pipefail
    ZSHRC="$HOME/.zshrc"
    MARKER_START="# >>> shellsmith >>>"
    MARKER_END="# <<< shellsmith <<<"
    BLOCK_FILE="{{ root }}/shell/zshrc_block.zsh"

    FULL_BLOCK="$(printf '%s\n%s\n%s' "$MARKER_START" "$(cat "$BLOCK_FILE")" "$MARKER_END")"

    touch "$ZSHRC"

    # Remove old development-wf markers if present
    if grep -qF "# >>> development-wf >>>" "$ZSHRC"; then
        tmpfile="$(mktemp)"
        awk '
            /^# >>> development-wf >>>/ { skip=1; next }
            /^# <<< development-wf <<</ { skip=0; next }
            !skip { print }
        ' "$ZSHRC" > "$tmpfile"
        mv "$tmpfile" "$ZSHRC"
        echo "  removed old development-wf block"
    fi

    if grep -qF "$MARKER_START" "$ZSHRC"; then
        tmpfile="$(mktemp)"
        awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$FULL_BLOCK" '
            $0 == start { skip=1; print block; next }
            $0 == end   { skip=0; next }
            !skip       { print }
        ' "$ZSHRC" > "$tmpfile"
        mv "$tmpfile" "$ZSHRC"
        echo "  updated shellsmith block in ~/.zshrc"
    else
        printf '\n%s\n' "$FULL_BLOCK" >> "$ZSHRC"
        echo "  appended shellsmith block to ~/.zshrc"
    fi

# Clone Ralph and symlink binary
ralph:
    #!/usr/bin/env bash
    set -euo pipefail
    RALPH_DIR="$HOME/.local/share/ralph"
    RALPH_BIN="$HOME/.local/bin/ralph"
    mkdir -p "$HOME/.local/bin"

    if [[ -d "$RALPH_DIR" ]]; then
        echo "  ok: ralph already cloned"
    else
        git clone https://github.com/cyanheads/ralph.git "$RALPH_DIR"
        echo "  cloned: ralph"
    fi

    if [[ -L "$RALPH_BIN" ]] && [[ "$(readlink "$RALPH_BIN")" == "$RALPH_DIR/ralph.sh" ]]; then
        echo "  ok: ralph symlink"
    else
        ln -sf "$RALPH_DIR/ralph.sh" "$RALPH_BIN"
        chmod +x "$RALPH_DIR/ralph.sh"
        echo "  linked: ralph → $RALPH_BIN"
    fi

# Install npm globals not covered by Nix
npm:
    #!/usr/bin/env bash
    set -euo pipefail
    PACKAGES=(
        "@anthropic-ai/claude-code-mcp"
        "@anthropic-ai/claude-code-sdk"
        "@anthropic-ai/claude-code-hooks"
        "@mariozechner/pi-coding-agent"
    )
    for pkg in "${PACKAGES[@]}"; do
        if npm list -g "$pkg" &>/dev/null 2>&1; then
            echo "  ok: $pkg"
        else
            npm install -g "$pkg"
            echo "  installed: $pkg"
        fi
    done

# Show current state
status:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "=== Symlinks ==="
    for pair in "$HOME/.config/nvim:{{ root }}/nvim" "$HOME/.tmux.conf:{{ root }}/tmux/tmux.conf"; do
        target="${pair%%:*}"
        expected="${pair#*:}"
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$expected" ]]; then
            echo "  ok: $target → $expected"
        else
            echo "  MISSING: $target"
        fi
    done

    echo ""
    echo "=== Shell block ==="
    if grep -qF "# >>> shellsmith >>>" "$HOME/.zshrc" 2>/dev/null; then
        echo "  ok: shellsmith block in ~/.zshrc"
    else
        echo "  MISSING: shellsmith block in ~/.zshrc"
    fi

    echo ""
    echo "=== Key binaries ==="
    for cmd in nvim tmux fzf claude node ralph just; do
        if loc="$(command -v "$cmd" 2>/dev/null)"; then
            echo "  ok: $cmd → $loc"
        else
            echo "  MISSING: $cmd"
        fi
    done

    echo ""
    echo "=== Ralph ==="
    if [[ -d "$HOME/.local/share/ralph" ]]; then
        echo "  ok: ralph cloned"
    else
        echo "  MISSING: ralph not cloned"
    fi

# Remove symlinks and zshrc block
clean:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Cleaning shellsmith..."

    for target in "$HOME/.config/nvim" "$HOME/.tmux.conf"; do
        if [[ -L "$target" ]]; then
            rm "$target"
            echo "  removed: $target"
        fi
    done

    if grep -qF "# >>> shellsmith >>>" "$HOME/.zshrc" 2>/dev/null; then
        tmpfile="$(mktemp)"
        awk '
            /^# >>> shellsmith >>>/ { skip=1; next }
            /^# <<< shellsmith <<</ { skip=0; next }
            !skip { print }
        ' "$HOME/.zshrc" > "$tmpfile"
        mv "$tmpfile" "$HOME/.zshrc"
        echo "  removed: shellsmith block from ~/.zshrc"
    fi

    echo "done (nvim/ and tmux/ configs are still in this repo)"

# Update flake and npm globals
update:
    nix flake update
    npm update -g
