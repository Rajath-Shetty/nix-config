# Quick Start

Get up and running in 5 minutes!

## Prerequisites

- NixOS installed
- Git available
- Text editor (vim, nano, or vscode)

## Step 1: Clone the Config

```bash
git clone https://github.com/yourusername/nixos-config
cd nixos-config
```

## Step 2: View Documentation

You have multiple ways to view docs:

### CLI (Quick Reference)
```bash
nixos-docs overview    # Quick overview
nixos-docs roles       # List roles
nixos-docs dev         # Dev environments
```

### Web (Full Documentation)
```bash
nix run .#docs-serve   # Builds and serves docs
# Open http://localhost:3000
```

### PWA (Visual Explorer)
```bash
nix run .#role-explorer  # Role/host explorer
# Open http://localhost:8080
# Click "Install" to add as app!
```

## Step 3: Create Your Host

```bash
nix run .#new-host my-laptop
```

This creates:
- `hosts/my-laptop/default.nix`
- `hosts/my-laptop/hardware-configuration.nix`

## Step 4: Get Hardware Config

```bash
sudo nixos-generate-config --show-hardware-config > hosts/my-laptop/hardware-configuration.nix
```

## Step 5: Configure Host

Edit `hosts/my-laptop/default.nix`:

```nix
{ config, lib, pkgs, hostname, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";  # ← Change this
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.yourname = {  # ← Change this
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
```

## Step 6: Assign Roles

Edit `parts/hosts.nix`:

```nix
{
  flake.nixosConfigurations = {
    my-laptop = self.lib.mkSystem {
      hostname = "my-laptop";
      roles = [
        "development"    # Git, Docker, VSCode, etc.
        "niri-desktop"   # Desktop environment
      ];
    };
  };
}
```

## Step 7: Build and Activate

```bash
sudo nixos-rebuild switch --flake .#my-laptop
```

## Done! 🎉

Your system now has:
- All packages from `development` and `niri-desktop` roles
- direnv for per-project environments
- Documentation accessible via `nixos-docs`
- Role explorer PWA

## Next Steps

- [Learn about roles](./roles/README.md)
- [Set up dev environments](./dev/README.md)
- [Add more hosts](./hosts/adding.md)
- [Create custom roles](./roles/creating.md)

## Quick Commands

```bash
# View docs
nixos-docs                    # CLI docs
nix run .#docs-serve          # Web docs
nix run .#role-explorer       # Visual explorer

# Manage hosts
nix run .#new-host NAME       # Create host
nix run .#new-role NAME       # Create role

# Dev environments
cd ~/myproject
echo "use flake ~/nixos-config#python" > .envrc
direnv allow

# Update system
cd ~/nixos-config
nix flake update
sudo nixos-rebuild switch --flake .#my-laptop
```

Happy NixOS-ing! 🚀
