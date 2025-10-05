#!/usr/bin/env bash
# NixOS Configuration Documentation Viewer

set -euo pipefail

DOCS_DIR="@docsDir@"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
${BLUE}NixOS Role-Based Configuration Documentation${NC}

Usage: nixos-docs [TOPIC]

${GREEN}Available Topics:${NC}
  ${YELLOW}overview${NC}       - System overview and quick start
  ${YELLOW}roles${NC}          - Available roles and how to use them
  ${YELLOW}hosts${NC}          - Managing multiple hosts
  ${YELLOW}dev${NC}            - Development environments (direnv, shells)
  ${YELLOW}webapp${NC}         - Role Explorer PWA
  ${YELLOW}install${NC}        - Fresh installation guide
  ${YELLOW}getting-started${NC} - Step-by-step tutorial
  ${YELLOW}all${NC}            - View all documentation

${GREEN}Examples:${NC}
  nixos-docs                 # Show this help
  nixos-docs overview        # Quick overview
  nixos-docs dev             # Development environments guide
  nixos-docs roles | less    # View roles with pager

${GREEN}Quick Commands:${NC}
  nixos-help                 # Alias for nixos-docs
  man nixos-config           # Man page (if installed)

${GREEN}Interactive Mode:${NC}
  nixos-docs -i              # Browse docs interactively
EOF
}

view_doc() {
    local topic="$1"
    local file=""

    case "$topic" in
        overview)
            file="$DOCS_DIR/README.md"
            ;;
        roles)
            cat << 'EOF'
# Available Roles

Your NixOS configuration uses a role-based system. Here are the available roles:

## 🎮 gaming
Steam, Discord, GameMode, graphics drivers, audio setup
Location: modules/roles/gaming.nix

Includes:
- Steam with remote play support
- Discord, Lutris, Wine
- GameMode for performance
- 32-bit graphics drivers
- PipeWire audio with low latency

## 💻 development
Git, Docker, VSCode, programming languages, terminal tools
Location: modules/roles/development.nix

Includes:
- Git, GitHub CLI
- Docker with auto-start
- VSCode, Vim, Neovim
- Python, Node.js, Go, Rust, C/C++
- direnv + nix-direnv for per-project environments
- Terminal tools: tmux, ripgrep, fd, bat, eza, fzf

## 🖥️ niri-desktop
Niri compositor (scrollable tiling), Wayland, desktop applications
Location: modules/roles/niri-desktop.nix

Includes:
- Niri window manager
- Wayland support
- File manager, browser, terminal
- Application launcher (fuzzel, rofi)
- Screenshot tools (grim, slurp)
- Notification daemon (mako)

## 🔧 server
SSH, monitoring, automatic updates, security hardening
Location: modules/roles/server.nix

Includes:
- SSH server (hardened)
- Prometheus node exporter
- Automatic garbage collection
- Firewall enabled
- No GUI packages

## Using Roles

In parts/hosts.nix:

```nix
my-laptop = self.lib.mkSystem {
  hostname = "my-laptop";
  roles = [ "development" "niri-desktop" ];
};
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#my-laptop
```

## Creating New Roles

```bash
nix run .#new-role media-center
# Edit modules/roles/media-center.nix
# Add to modules/roles/default.nix
```

See: nixos-docs dev
EOF
            return
            ;;
        hosts)
            file="$DOCS_DIR/README.md"
            echo "# Managing Hosts" | cat - "$file" | grep -A 100 "Example Host Configuration"
            return
            ;;
        dev)
            file="$DOCS_DIR/DEV_ENVIRONMENTS.md"
            ;;
        webapp)
            file="$DOCS_DIR/webapp/README.md"
            ;;
        install|fresh)
            file="$DOCS_DIR/FRESH_INSTALL.md"
            ;;
        getting-started|tutorial)
            file="$DOCS_DIR/GETTING_STARTED.md"
            ;;
        all)
            echo -e "${GREEN}=== README ===${NC}"
            cat "$DOCS_DIR/README.md"
            echo -e "\n${GREEN}=== DEVELOPMENT ENVIRONMENTS ===${NC}"
            cat "$DOCS_DIR/DEV_ENVIRONMENTS.md"
            echo -e "\n${GREEN}=== GETTING STARTED ===${NC}"
            cat "$DOCS_DIR/GETTING_STARTED.md"
            return
            ;;
        *)
            echo -e "${YELLOW}Unknown topic: $topic${NC}"
            show_help
            return 1
            ;;
    esac

    if [ -f "$file" ]; then
        if command -v glow &> /dev/null; then
            glow "$file"
        elif command -v bat &> /dev/null; then
            bat --style=plain --language=markdown "$file"
        else
            cat "$file"
        fi
    else
        echo -e "${YELLOW}Documentation file not found: $file${NC}"
        return 1
    fi
}

interactive_mode() {
    if ! command -v fzf &> /dev/null; then
        echo "Interactive mode requires fzf. Install it or use: nixos-docs TOPIC"
        return 1
    fi

    local topics=(
        "overview:System overview and quick start"
        "roles:Available roles and usage"
        "hosts:Managing multiple hosts"
        "dev:Development environments"
        "webapp:Role Explorer PWA"
        "install:Fresh installation guide"
        "getting-started:Step-by-step tutorial"
    )

    local choice=$(printf '%s\n' "${topics[@]}" | fzf --header="Select Documentation Topic" --delimiter=: --with-nth=2)
    local topic=$(echo "$choice" | cut -d: -f1)

    view_doc "$topic"
}

# Main
case "${1:-}" in
    -h|--help|help)
        show_help
        ;;
    -i|--interactive)
        interactive_mode
        ;;
    "")
        show_help
        ;;
    *)
        view_doc "$1"
        ;;
esac
