# Shellsmith – AI dev workflow
# Usage: nix develop --command just setup

set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
timestamp := `date +%Y%m%d-%H%M%S`

# Default recipe: run full setup
setup: link zshrc npm
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

# Install npm globals not covered by Nix
npm:
    #!/usr/bin/env bash
    set -euo pipefail
    export NPM_CONFIG_PREFIX="$HOME/.local"
    PACKAGES=(
        "@mariozechner/pi-coding-agent"
    )
    for pkg in "${PACKAGES[@]}"; do
        if npm list -g --prefix="$HOME/.local" "$pkg" &>/dev/null 2>&1; then
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
    echo "=== MCP servers ==="
    python3 "{{ root }}/mcp/status.py" short

    echo ""
    echo "=== Key binaries ==="
    for cmd in nvim tmux fzf claude node just; do
        if loc="$(command -v "$cmd" 2>/dev/null)"; then
            echo "  ok: $cmd → $loc"
        else
            echo "  MISSING: $cmd"
        fi
    done

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

# Configure MCP servers for Claude Code / Pi
# Usage: just mcp              (interactive picker)
#        just mcp github       (single server)
#        just mcp github jira  (multiple servers)
mcp *SERVERS:
    {{ root }}/mcp/setup.sh {{ SERVERS }}

# List available MCP server templates
mcp-list:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Available MCP servers:"
    for f in "{{ root }}"/mcp/*.json; do
        [[ -f "$f" ]] || continue
        name="$(basename "$f" .json)"
        desc=$(python3 -c "import json; d=json.load(open('$f')); k=list(d.keys())[0]; print(d[k].get('description',''))" 2>/dev/null || echo "")
        echo "  $name — $desc"
    done

# Show MCP servers currently configured in Claude Code
mcp-status:
    @echo "=== MCP servers in ~/.claude.json ==="
    @python3 "{{ root }}/mcp/status.py" full

# Update flake and npm globals
update:
    nix flake update
    npm update -g
