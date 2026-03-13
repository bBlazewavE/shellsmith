# === Shellsmith ===

# Nix
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Don't error on unmatched globs (fixes "no matches found" with ? * [] in commands)
setopt NO_NOMATCH

# Default editor
export EDITOR='nvim'
export VISUAL='nvim'

# PATH additions
export PATH="$HOME/.local/bin:$PATH"

# fzf shell integration (Ctrl-R history, Ctrl-T files, Alt-C dirs)
source <(fzf --zsh)

# Starship prompt
eval "$(starship init zsh)"

# Aliases
alias lg='lazygit'
alias y='yazi'
alias v='nvim'
alias cc='claude'
alias orch='python3 ~/.shellsmith/orchestrator/orch.py'

# Dev session: Neovim on top, Pi on bottom
dev() {
  local session="${1:-dev}"
  tmux new-session -d -s "$session" -n code 'nvim "+lua vim.defer_fn(function() require(\"telescope.builtin\").find_files() end, 100)"'
  tmux split-window -v -t "$session" -l 30% 'pi'
  tmux select-pane -t "$session:1.1"
  tmux attach -t "$session"
}
