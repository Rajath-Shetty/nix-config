#!/usr/bin/env bash
# Quick start script for setting up a new host

set -euo pipefail

echo "==================================="
echo "NixOS Role-Based Config Quick Start"
echo "==================================="
echo

# Get hostname
HOSTNAME="${1:-$(hostname)}"
echo "Setting up configuration for: $HOSTNAME"
echo

# Check if we're in the right directory
if [ ! -f "flake.nix" ]; then
    echo "Error: Please run this script from the nixos-config directory"
    exit 1
fi

# Check if host already exists
if [ -d "hosts/$HOSTNAME" ]; then
    echo "Error: Host '$HOSTNAME' already exists"
    echo "Use a different name or delete hosts/$HOSTNAME first"
    exit 1
fi

# Create host directory
echo "Creating host directory..."
mkdir -p "hosts/$HOSTNAME"

# Generate or copy hardware configuration
if [ -f "/etc/nixos/hardware-configuration.nix" ]; then
    echo "Copying hardware configuration from /etc/nixos..."
    cp /etc/nixos/hardware-configuration.nix "hosts/$HOSTNAME/"
else
    echo "Generating new hardware configuration..."
    sudo nixos-generate-config --show-hardware-config > "hosts/$HOSTNAME/hardware-configuration.nix"
fi

# Create default.nix
echo "Creating default configuration..."
cat > "hosts/$HOSTNAME/default.nix" <<EOF
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
  time.timeZone = "America/New_York";  # TODO: Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # User account
  users.users.user = {  # TODO: Change 'user' to your username
    isNormalUser = true;
    description = "User";  # TODO: Change description
    extraGroups = [ "wheel" "networkmanager" ];
    # Set password with: mkpasswd -m sha-512
    # hashedPassword = "";
    initialPassword = "changeme";  # Change this on first login!
  };

  # Allow unfree packages (needed for some roles)
  nixpkgs.config.allowUnfree = true;

  # DO NOT CHANGE THIS
  system.stateVersion = "24.05";
}
EOF

echo
echo "Host configuration created!"
echo
echo "Next steps:"
echo
echo "1. Edit hosts/$HOSTNAME/default.nix:"
echo "   - Set your timezone"
echo "   - Configure your user account"
echo "   - Review hardware-configuration.nix"
echo
echo "2. Register host in parts/hosts.nix by adding:"
echo
echo "    $HOSTNAME = self.lib.mkSystem {"
echo "      hostname = \"$HOSTNAME\";"
echo "      roles = [ \"development\" ];  # Choose your roles"
echo "    };"
echo
echo "3. Build and activate:"
echo "   sudo nixos-rebuild switch --flake .#$HOSTNAME"
echo
echo "Available roles:"
echo "  - gaming        (Steam, Discord, gaming tools)"
echo "  - development   (Git, Docker, VSCode, languages)"
echo "  - niri-desktop  (Desktop environment)"
echo "  - server        (SSH, monitoring, hardening)"
echo
echo "See GETTING_STARTED.md for detailed instructions"
echo
