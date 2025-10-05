{ inputs, ... }:

{
  perSystem = { config, pkgs, ... }: {
    devShells = {
      # Default shell for managing NixOS configs
      default = pkgs.mkShell {
        packages = with pkgs; [
          nixpkgs-fmt
          nil # Nix language server
          git
        ];

        shellHook = ''
          echo "==> NixOS Role-Based Configuration Environment"
          echo ""
          echo "Available commands:"
          echo "  nix run .#bootstrap      - Bootstrap a fresh NixOS install"
          echo "  nix run .#role-explorer  - Web GUI for exploring roles"
          echo "  nix run .#new-role       - Create a new role"
          echo "  nix run .#new-host       - Create a new host"
          echo ""
          echo "Build a configuration:"
          echo "  nixos-rebuild switch --flake .#hostname"
          echo ""
          echo "Other dev shells available:"
          echo "  nix develop .#python    - Python development"
          echo "  nix develop .#rust      - Rust development"
          echo "  nix develop .#node      - Node.js development"
          echo "  nix develop .#go        - Go development"
          echo ""
        '';
      };

      # Python development environment
      python = pkgs.mkShell {
        packages = with pkgs; [
          python311
          python311Packages.pip
          python311Packages.virtualenv
          python311Packages.pytest
          python311Packages.black
          python311Packages.ipython
          poetry
        ];

        shellHook = ''
          echo "🐍 Python Development Environment"
          echo "Python: $(python --version)"
          echo "Poetry: $(poetry --version)"
        '';
      };

      # Rust development environment
      rust = pkgs.mkShell {
        packages = with pkgs; [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
        ];

        shellHook = ''
          echo "🦀 Rust Development Environment"
          echo "Rust: $(rustc --version)"
          echo "Cargo: $(cargo --version)"
        '';

        RUST_BACKTRACE = "1";
      };

      # Node.js development environment
      node = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_20
          nodePackages.npm
          nodePackages.pnpm
          nodePackages.yarn
          nodePackages.typescript
          nodePackages.typescript-language-server
        ];

        shellHook = ''
          echo "📦 Node.js Development Environment"
          echo "Node: $(node --version)"
          echo "npm: $(npm --version)"
        '';
      };

      # Go development environment
      go = pkgs.mkShell {
        packages = with pkgs; [
          go
          gopls
          gotools
          go-tools
        ];

        shellHook = ''
          echo "🐹 Go Development Environment"
          echo "Go: $(go version)"
        '';
      };

      # C/C++ development environment
      cpp = pkgs.mkShell {
        packages = with pkgs; [
          gcc
          clang
          cmake
          gnumake
          gdb
          valgrind
          clang-tools
        ];

        shellHook = ''
          echo "⚙️  C/C++ Development Environment"
          echo "GCC: $(gcc --version | head -n1)"
          echo "Clang: $(clang --version | head -n1)"
        '';
      };

      # Full-stack web development
      web = pkgs.mkShell {
        packages = with pkgs; [
          nodejs_20
          nodePackages.npm
          nodePackages.typescript
          nodePackages.vscode-langservers-extracted
          python311
          python311Packages.flask
          python311Packages.django
        ];

        shellHook = ''
          echo "🌐 Full-Stack Web Development Environment"
          echo "Node: $(node --version)"
          echo "Python: $(python --version)"
        '';
      };
    };
  };
}
