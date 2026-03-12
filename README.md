# Shellsmith

A complete AI-powered development environment for macOS. Declarative packages via **Nix**, composable setup via **Just**, reproducible on any Mac.

## Quick Start

### Fresh Mac

```bash
git clone https://github.com/bBlazewavE/shellsmith.git ~/.shellsmith
cd ~/.shellsmith
./bootstrap.sh                      # installs Xcode CLI tools + Nix
nix develop --command just setup    # links configs, injects zshrc, installs npm extras
source ~/.zshrc
```

### Existing Mac (Nix already installed)

```bash
cd ~/.shellsmith
nix develop --command just setup
```

## Architecture

```
flake.nix              ← declares all packages (Nix devShell)
justfile               ← recipes: setup, link, zshrc, npm, mcp, status, clean, update
bootstrap.sh           ← one-time script (Xcode CLI + Nix)
shell/zshrc_block.zsh  ← shell config injected into ~/.zshrc
nvim/                  ← Neovim config (symlinked to ~/.config/nvim)
tmux/                  ← tmux config (symlinked to ~/.tmux.conf)
mcp/                   ← MCP server templates (GitHub, Jira, Slack, Linear, Notion)
```

**Install flow:** `bootstrap.sh` → `nix develop` → `just setup`

## What Gets Installed

| Tool | Purpose | Installed via |
|------|---------|--------------|
| **Neovim** | Primary editor with LSP, completion, fuzzy finding | Nix |
| **tmux** | Terminal multiplexer for multi-pane sessions | Nix |
| **Claude Code** | AI coding assistant (CLI) | Nix (community flake) |
| **Pi** | AI coding agent | npm |
| **lazygit** | Terminal UI for git | Nix |
| **fzf** | Fuzzy finder (files, history, dirs) | Nix |
| **fd** | Fast file finder (used by fzf/Telescope) | Nix |
| **ripgrep** | Fast text search (used by Telescope) | Nix |
| **yazi** | Terminal file manager | Nix |
| **Starship** | Cross-shell prompt | Nix |
| **gh** | GitHub CLI | Nix |
| **Node.js 22** | Required for npm packages & LSP servers | Nix |
| **Just** | Command runner for setup recipes | Nix |

## Just Recipes

| Recipe | What it does |
|--------|-------------|
| `just setup` | Runs link, zshrc, npm (default) |
| `just link` | Symlinks nvim/ and tmux.conf (with backup) |
| `just zshrc` | Injects shell block into ~/.zshrc between markers |
| `just npm` | Installs npm globals not covered by Nix |
| `just mcp` | Interactive MCP server setup (GitHub, Jira, Slack, etc.) |
| `just mcp github` | Configure a specific MCP server |
| `just mcp-list` | List available MCP server templates |
| `just mcp-status` | Show configured MCP servers |
| `just status` | Shows current state (symlinks, packages, MCP, shell block) |
| `just clean` | Removes symlinks and zshrc block |
| `just update` | Runs `nix flake update` and `npm update -g` |

All recipes are idempotent — safe to run repeatedly.

## Components

### Neovim

Full IDE-like config with lazy.nvim plugin manager. Plugins auto-install on first launch.

**Plugins included:**
- **Theme:** Catppuccin Mocha
- **LSP:** Mason + nvim-lspconfig (auto-installs servers for Lua, Python, TypeScript, Go, Rust, HTML, CSS, JSON, YAML, Bash)
- **Completion:** nvim-cmp with LSP, buffer, path, and snippet sources
- **Fuzzy finding:** Telescope with fzf-native
- **Treesitter:** Syntax highlighting, text objects, incremental selection
- **File tree:** Neo-tree
- **Git:** Gitsigns (inline diff markers)
- **UI:** Bufferline, Lualine, Which-key, dressing.nvim, nvim-notify
- **Editing:** Autopairs, Comment.nvim, nvim-surround, indent-blankline
- **Other:** Smart-splits, auto-save (off by default, toggle with `:ASToggle`)

### tmux

- **Prefix:** `Ctrl-a` (not the default `Ctrl-b`)
- **Mouse:** Enabled (scroll, click, resize)
- **True color:** Configured for 256-color terminals
- **Catppuccin-matching status bar**

### Shell (zsh)

A marker-delimited block is injected into `~/.zshrc` (your existing config is preserved). Includes:
- Nix daemon sourcing
- `EDITOR` / `VISUAL` set to nvim
- fzf shell integration
- Starship prompt
- Aliases and the `dev` function

### MCP Servers (connect AI to external services)

MCP (Model Context Protocol) lets Claude Code and Pi interact with external services — search Jira issues, create GitHub PRs, post to Slack, all from your AI coding session.

**Available servers:**

| Server | Service | Auth required |
|--------|---------|---------------|
| `github` | Issues, PRs, repos, code search | `gh auth login` |
| `jira` | Jira issues, Confluence pages | Atlassian API token |
| `slack` | Channels, messages, threads | Slack bot token |
| `linear` | Issues, projects, teams | Linear API key |
| `notion` | Pages, databases, search | Notion API key |

**Quick setup:**

```bash
# Interactive — pick which servers to enable
nix develop --command just mcp

# Direct — configure specific servers
nix develop --command just mcp github
nix develop --command just mcp github jira slack

# Check what's configured
just mcp-status
```

GitHub is zero-config if you've already run `gh auth login` — it uses the GitHub CLI directly.

For token-based services (Jira, Slack, etc.), the setup will prompt for credentials or read them from environment variables. Templates are in `mcp/` — add your own by dropping a JSON file there.

### Pi (primary AI interface)

Pi is the main AI pane in the `dev` session. It supports 15+ model providers — use Claude for complex tasks and switch to cheaper models for quick questions to optimize token spend. Claude Code is installed as a provider inside Pi.

After install, set up authentication. You can use either:
- **Claude Code OAuth token:** `claude setup-token` then `export ANTHROPIC_API_KEY=<token>`
- **Console API key:** Get one from console.anthropic.com
- **Other providers:** Set `GOOGLE_API_KEY`, `OPENAI_API_KEY`, etc.

## Shortcuts & Aliases

### Shell

| Command | Action |
|---------|--------|
| `dev` | Launch tmux session: Neovim (file picker) + Pi |
| `dev myproject` | Same, with custom session name |
| `v` | `nvim` |
| `lg` | `lazygit` |
| `y` | `yazi` |
| `cc` | `claude` |

### tmux

| Key | Action |
|-----|--------|
| `Ctrl-a \|` | Split pane horizontally |
| `Ctrl-a -` | Split pane vertically |
| `Alt-Arrow` | Navigate panes (no prefix) |
| `Ctrl-a c` | New window |
| `Ctrl-a r` | Reload tmux config |

### Neovim

| Key | Action |
|-----|--------|
| `Space` | Leader key |
| `Space e` | Toggle file tree |
| `Space ff` | Find files |
| `Space fg` | Live grep |
| `Space fb` | Find buffers |
| `Space fr` | Recent files |
| `Shift-H/L` | Previous/next buffer |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover docs |
| `Space ca` | Code action |
| `Space rn` | Rename symbol |
| `Space d` | Show diagnostics |
| `gc` | Toggle comment |
| `Ctrl-s` | Save file |

## Updating

All configs are symlinked, so pulling the repo updates them:
```bash
cd ~/.shellsmith
git pull
```

For tool and package updates:
```bash
nix develop --command just update
```

## Uninstalling

```bash
cd ~/.shellsmith
nix develop --command just clean
```

This removes symlinks and the zshrc block. To fully clean up:
```bash
# Remove installed data
rm -rf ~/.local/share/nvim/lazy    # Neovim plugins
# Remove the repo
rm -rf ~/.shellsmith
```

## Verification

```bash
just status                # check symlinks, packages, shell block
which claude               # should resolve to Nix store or npm global
which nvim                 # should resolve to Nix store
nix flake check            # validate the flake
source ~/.zshrc && dev     # launch the tmux dev session
```

## Incident Resolution Playbook

### Neovim plugins fail to install
```bash
rm -rf ~/.local/share/nvim/lazy
nvim  # lazy.nvim will re-bootstrap
```

### LSP server not starting
```bash
# Inside Neovim:
:Mason          # Check server status
:LspInfo        # Check attached clients
:LspLog         # View error logs
```

### tmux not using correct colors
Ensure your terminal emulator supports true color and is set to `xterm-256color`. Add to terminal settings if needed:
```bash
export TERM=xterm-256color
```

### Claude Code not found
```bash
which claude               # Check PATH
just status                # Check overall state
source ~/.zshrc            # Reload shell
```

## Troubleshooting

**Icons look broken?** Install a Nerd Font:
```bash
# Via Nix (ad-hoc)
nix-env -iA nixpkgs.nerd-fonts.jetbrains-mono
```
Then set it as your terminal's font.

**Telescope grep not working?** Ensure ripgrep is available — it should be if you're in the Nix dev shell:
```bash
which rg
```

**fzf keybindings not working?** Make sure `source <(fzf --zsh)` runs after Oh My Zsh is sourced in your `.zshrc`.

## License

MIT
