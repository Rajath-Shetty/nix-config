#!/usr/bin/env bash
######################################
# NixOS Role-Based Configuration Installer
# Inspired by ZaneyOS
######################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  NixOS Role-Based Configuration Install   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}❌ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}▶ $1${NC}"
}

# Check prerequisites
check_requirements() {
    print_step "Checking system requirements..."

    # Check if running on NixOS
    if [ ! -f /etc/NIXOS ]; then
        print_error "This script must be run on NixOS"
        exit 1
    fi

    # Check if in repository directory
    if [ ! -f "flake.nix" ]; then
        print_error "Not in nixos-config directory"
        echo ""
        echo "Usage:"
        echo "  1. Clone the repository:"
        echo "     git clone <your-repo-url>"
        echo "     cd nixos-config"
        echo ""
        echo "  2. Run this script:"
        echo "     bash install.sh"
        exit 1
    fi

    # Check for required commands
    for cmd in git nixos-generate-config nixos-rebuild; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command not found: $cmd"
            exit 1
        fi
    done

    print_success "All requirements met"
}

# Get user input with validation
get_hostname() {
    local default_hostname
    default_hostname=$(hostname)

    echo ""
    print_step "Configure hostname"
    echo -e "${CYAN}Current hostname: ${default_hostname}${NC}"
    read -p "Enter hostname (or press Enter to use current): " input_hostname

    HOSTNAME="${input_hostname:-$default_hostname}"
    print_info "Using hostname: $HOSTNAME"
}

get_username() {
    echo ""
    print_step "Configure user account"
    read -p "Enter username (default: nixos): " input_username

    USERNAME="${input_username:-nixos}"
    print_info "Using username: $USERNAME"
}

get_timezone() {
    echo ""
    print_step "Configure timezone"
    local default_tz="UTC"

    # Try to detect current timezone
    if [ -f /etc/timezone ]; then
        default_tz=$(cat /etc/timezone)
    elif [ -L /etc/localtime ]; then
        default_tz=$(readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||')
    fi

    echo -e "${CYAN}Detected timezone: ${default_tz}${NC}"
    read -p "Enter timezone (or press Enter to use detected): " input_tz

    TIMEZONE="${input_tz:-$default_tz}"
    print_info "Using timezone: $TIMEZONE"
}

get_roles() {
    echo ""
    print_step "Select roles for this system"
    echo ""
    echo "Available roles:"
    echo "  1) development  - Development tools and environment"
    echo "  2) gaming       - Gaming setup with necessary drivers"
    echo "  3) niri-desktop - Niri desktop environment"
    echo "  4) server       - Server configuration"
    echo ""
    read -p "Enter roles (space-separated, e.g., '1 2' or 'development gaming'): " roles_input

    # Parse roles
    ROLES=()
    for role in $roles_input; do
        case $role in
            1|development) ROLES+=("development") ;;
            2|gaming) ROLES+=("gaming") ;;
            3|niri-desktop) ROLES+=("niri-desktop") ;;
            4|server) ROLES+=("server") ;;
            *) print_warning "Unknown role: $role (skipping)" ;;
        esac
    done

    if [ ${#ROLES[@]} -eq 0 ]; then
        ROLES=("development")
        print_warning "No valid roles selected, using default: development"
    else
        print_info "Selected roles: ${ROLES[*]}"
    fi
}

# Backup existing configuration
backup_existing_config() {
    if [ -d /etc/nixos ]; then
        local backup_dir="/etc/nixos.backup-$(date +%Y%m%d-%H%M%S)"
        print_step "Backing up existing /etc/nixos to $backup_dir"
        sudo mv /etc/nixos "$backup_dir"
        print_success "Backup created at $backup_dir"
    fi
}

# Update flake inputs
update_flake() {
    print_step "Updating flake inputs..."

    # Remove old lock file if it exists
    if [ -f flake.lock ]; then
        print_info "Removing old flake.lock"
        rm -f flake.lock
    fi

    # Update flake
    if nix flake update; then
        print_success "Flake inputs updated"
    else
        print_warning "Flake update failed, but continuing..."
    fi
}

# Copy configuration to /etc/nixos
install_config() {
    print_step "Installing configuration to /etc/nixos"

    sudo mkdir -p /etc/nixos
    sudo cp -r "$(pwd)"/* /etc/nixos/

    # Ensure proper ownership
    sudo chown -R root:root /etc/nixos

    print_success "Configuration copied to /etc/nixos"
}

# Generate hardware configuration
generate_hardware_config() {
    print_step "Generating hardware configuration..."

    local hw_config_dir="/etc/nixos/hosts/$HOSTNAME"
    sudo mkdir -p "$hw_config_dir"

    sudo nixos-generate-config --show-hardware-config | sudo tee "$hw_config_dir/hardware-configuration.nix" > /dev/null

    print_success "Hardware configuration generated"
}

# Create host configuration
create_host_config() {
    local host_dir="/etc/nixos/hosts/$HOSTNAME"

    if [ -f "$host_dir/default.nix" ]; then
        print_info "Host configuration already exists, updating only hardware config"
        return
    fi

    print_step "Creating host configuration for $HOSTNAME"

    # Detect NixOS version
    local nixos_version
    nixos_version=$(nixos-version | cut -d. -f1,2)
    print_info "Detected NixOS version: $nixos_version"

    # Create default.nix
    sudo tee "$host_dir/default.nix" > /dev/null << EOF
{ config, lib, pkgs, hostname, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.hostName = "$HOSTNAME";
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "$TIMEZONE";
  i18n.defaultLocale = "en_US.UTF-8";

  # User account
  users.users.$USERNAME = {
    isNormalUser = true;
    description = "$USERNAME";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # DO NOT CHANGE - detected from your NixOS version
  system.stateVersion = "$nixos_version";
}
EOF

    print_success "Host configuration created"
}

# Update parts/hosts.nix
update_hosts_file() {
    local hosts_file="/etc/nixos/parts/hosts.nix"

    print_step "Checking parts/hosts.nix registration"

    # Check if hostname is already registered
    if sudo grep -q "\"$HOSTNAME\"" "$hosts_file" 2>/dev/null; then
        print_success "Host '$HOSTNAME' already registered"
        return
    fi

    print_warning "Host '$HOSTNAME' not registered in parts/hosts.nix"

    # Format roles array
    local roles_str="[ "
    for role in "${ROLES[@]}"; do
        roles_str+="\"$role\" "
    done
    roles_str+="]"

    # Auto-add the host configuration
    print_step "Adding $HOSTNAME to parts/hosts.nix..."

    # Create the host entry
    local host_entry="
    # $HOSTNAME
    $HOSTNAME = self.lib.mkSystem {
      hostname = \"$HOSTNAME\";
      roles = $roles_str;
    };
"

    # Insert before the closing brace and comment
    sudo sed -i "/# Add more hosts here.../i\\$host_entry" "$hosts_file"

    print_success "Host '$HOSTNAME' added to configuration"

    echo ""
    read -p "Press Enter to review parts/hosts.nix (Ctrl+C to skip)..."
    sudo "${EDITOR:-nano}" "$hosts_file" || true
}

# Enable experimental features
enable_flakes() {
    print_step "Enabling Nix flakes..."

    # Check if already enabled
    if sudo grep -q "experimental-features" /etc/nix/nix.conf 2>/dev/null; then
        print_info "Flakes already enabled"
        return
    fi

    # Try to enable via nix.conf
    if sudo mkdir -p /etc/nix 2>/dev/null && echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf > /dev/null 2>&1; then
        print_success "Flakes enabled in /etc/nix/nix.conf"
    else
        print_warning "/etc/nix/nix.conf is read-only (managed by NixOS config)"
        print_info "Flakes will be enabled in the host configuration instead"
    fi
}

# Build and switch to new configuration
build_system() {
    print_step "Building NixOS configuration..."
    echo ""
    print_warning "This may take a while on first build..."
    echo ""

    cd /etc/nixos

    if sudo nixos-rebuild switch --flake ".#$HOSTNAME"; then
        return 0
    else
        print_error "Build failed"
        echo ""
        echo "Common issues:"
        echo "  1. Check that $HOSTNAME is registered in parts/hosts.nix"
        echo "  2. Verify flake.nix syntax is correct"
        echo "  3. Check hardware-configuration.nix is valid"
        echo ""
        echo "To retry manually:"
        echo "  cd /etc/nixos"
        echo "  sudo nixos-rebuild switch --flake '.#$HOSTNAME'"
        return 1
    fi
}

# Print success banner
print_success_banner() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ Install Complete! ✅          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your system is now configured with:"
    echo "  • Hostname: $HOSTNAME"
    echo "  • Username: $USERNAME"
    echo "  • Timezone: $TIMEZONE"
    echo "  • Roles: ${ROLES[*]}"
    echo "  • Configuration: /etc/nixos"
    echo ""
    echo "Next steps:"
    echo "  1. Change your password: passwd"
    echo "  2. Reboot if kernel was updated: sudo reboot"
    echo "  3. Customize: cd /etc/nixos && nano hosts/$HOSTNAME/default.nix"
    echo ""
    echo "Tools available:"
    echo "  nixos-docs                 # View documentation"
    echo "  nix run .#role-explorer    # Web GUI"
    echo ""
    print_warning "Default password is 'changeme' - CHANGE IT NOW!"
    echo ""
}

# Main installation flow
main() {
    print_header

    # Pre-flight checks
    check_requirements

    # Update flake first
    update_flake

    # Gather user configuration
    get_hostname
    get_username
    get_timezone
    get_roles

    echo ""
    print_info "Summary:"
    echo "  Hostname: $HOSTNAME"
    echo "  Username: $USERNAME"
    echo "  Timezone: $TIMEZONE"
    echo "  Roles: ${ROLES[*]}"
    echo ""
    read -p "Continue with installation? (y/N): " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi

    # Backup and install
    backup_existing_config
    install_config

    # Configure system
    generate_hardware_config
    create_host_config
    update_hosts_file
    enable_flakes

    # Build
    if build_system; then
        print_success_banner
    else
        print_error "Installation incomplete - please fix errors and retry"
        exit 1
    fi
}

# Run main
main "$@"
