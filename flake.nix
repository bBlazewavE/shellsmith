{
  description = "Shellsmith – AI dev workflow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    claude-code-nix.url = "github:sadjow/claude-code-nix";
  };

  outputs = { self, nixpkgs, flake-utils, claude-code-nix }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        claude-code = claude-code-nix.packages.${system}.default;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            # System tools
            pkgs.tmux
            pkgs.fd
            pkgs.fzf
            pkgs.lazygit
            pkgs.yazi
            pkgs.starship
            pkgs.neovim
            pkgs.ripgrep
            pkgs.gh
            pkgs.nodejs_22
            pkgs.just

            # AI tools (from community flake)
            claude-code
          ];

          shellHook = ''
            echo "shellsmith: dev shell active"
          '';
        };
      }
    );
}
