#!/usr/bin/env bash
# Bootstrap script for fresh NixOS installs
# Run this from within the cloned repository

set -euo pipefail

HOSTNAME="${1:-$(hostname)}"

# Check if we're in the repo
if [ ! -f "flake.nix" ]; then
  cat << 'EOF'
❌ Error: Not in nixos-config directory

Usage:
  1. Clone the repository first:
     git clone https://github.com/yourusername/nixos-config
     cd nixos-config

  2. Run this script:
     bash install.sh [hostname]

Examples:
  bash install.sh                 # Uses current hostname
  bash install.sh my-laptop       # Use custom hostname

This script will:
  1. Copy this configuration to /etc/nixos
  2. Generate hardware configuration
  3. Detect NixOS version for system.stateVersion
  4. Create/update host configuration
  5. Build and switch to new configuration

EOF
  exit 1
fi

echo "╔════════════════════════════════════════════╗"
echo "║  NixOS Role-Based Configuration Install   ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Current directory: $(pwd)"
echo "Hostname:          $HOSTNAME"
echo ""

# Check we're on NixOS
if [ ! -f /etc/NIXOS ]; then
  echo "❌ Error: This must be run on NixOS"
  exit 1
fi

# Backup existing config
if [ -d /etc/nixos ]; then
  BACKUP="/etc/nixos.backup-$(date +%Y%m%d-%H%M%S)"
  echo "📦 Backing up /etc/nixos to $BACKUP"
  sudo mv /etc/nixos "$BACKUP"
fi

# Copy current directory to /etc/nixos
echo ""
echo "📥 Copying configuration to /etc/nixos..."
sudo cp -r "$(pwd)" /etc/nixos
cd /etc/nixos

# Detect NixOS version
NIXOS_VERSION=$(nixos-version | cut -d. -f1,2)
echo ""
echo "🔍 Detected NixOS version: $NIXOS_VERSION"

# Generate hardware configuration
echo ""
echo "🔧 Generating hardware configuration..."
sudo nixos-generate-config --show-hardware-config > /tmp/hardware-config.nix

# Check if host directory exists
if [ ! -d "hosts/$HOSTNAME" ]; then
  echo ""
  echo "⚠️  Host '$HOSTNAME' not found in configuration"
  echo "   Creating new host..."

  sudo mkdir -p "hosts/$HOSTNAME"
  sudo cp /tmp/hardware-config.nix "hosts/$HOSTNAME/hardware-configuration.nix"

  # Create default.nix with correct stateVersion
  sudo tee "hosts/$HOSTNAME/default.nix" > /dev/null << EOF
{ config, lib, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "UTC";  # TODO: Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # User account
  users.users.nixos = {
    isNormalUser = true;
    description = "NixOS User";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";  # Change on first login!
  };

  # Allow unfree packages (needed for some roles)
  nixpkgs.config.allowUnfree = true;

  # DO NOT CHANGE - detected from your NixOS version
  system.stateVersion = "$NIXOS_VERSION";
}
EOF

  echo ""
  echo "⚠️  Host created but NOT registered in parts/hosts.nix"
  echo ""
  echo "You need to manually add this to parts/hosts.nix:"
  echo ""
  echo "  $HOSTNAME = self.lib.mkSystem {"
  echo "    hostname = \"$HOSTNAME\";"
  echo "    roles = [ \"development\" ];  # Choose your roles"
  echo "  };"
  echo ""
  echo "Available roles: gaming, development, niri-desktop, server"
  echo ""

  # Ask user to edit
  read -p "Press Enter to open parts/hosts.nix for editing (Ctrl+C to skip)..."
  ${EDITOR:-nano} parts/hosts.nix || true
else
  echo "✅ Host '$HOSTNAME' found in configuration"
  echo "   Updating hardware configuration..."
  sudo cp /tmp/hardware-config.nix "hosts/$HOSTNAME/hardware-configuration.nix"
fi

# Enable experimental features for the build
echo ""
echo "🔧 Enabling flakes for build..."
sudo mkdir -p /etc/nix
if ! grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf
fi

# Build and switch
echo ""
echo "🔨 Building NixOS configuration..."
echo "   This may take a while on first build..."
echo ""

sudo nixos-rebuild switch --flake ".#$HOSTNAME"

echo ""
echo "╔════════════════════════════════════════════╗"
echo "║          ✅ Install Complete! ✅          ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Your system is now configured with:"
echo "  • Role-based NixOS configuration"
echo "  • Configuration at: /etc/nixos"
echo "  • Hostname: $HOSTNAME"
echo "  • State version: $NIXOS_VERSION"
echo ""
echo "Next steps:"
echo "  1. Reboot (if kernel was updated)"
echo "  2. Change your password: passwd"
echo "  3. Customize: cd /etc/nixos && nano hosts/$HOSTNAME/default.nix"
echo ""
echo "Tools available:"
echo "  nixos-docs                 # View documentation"
echo "  nix run .#role-explorer    # Web GUI"
echo ""
echo "Default credentials:"
echo "  User: nixos"
echo "  Password: nixos (CHANGE THIS!)"
echo ""
