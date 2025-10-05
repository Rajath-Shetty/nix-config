# Getting Started with Role-Based NixOS

This guide will walk you through setting up your first role-based NixOS configuration.

## Prerequisites

- A NixOS installation (fresh or existing)
- Git installed
- Basic understanding of Nix

## Step 1: Understanding Roles

Instead of managing hundreds of packages per host, you define **roles**:

```nix
# Traditional NixOS
environment.systemPackages = [
  steam discord nvidia-driver gamemode wine lutris ...
  git vscode docker python nodejs rust ...
];

# Role-based approach
roles = [ "gaming" "development" ];
```

## Step 2: Fork or Clone This Repo

```bash
git clone https://github.com/yourusername/nixos-config.git
cd nixos-config
```

## Step 3: Create Your First Host

Let's create a configuration for your current machine:

```bash
# Enter development environment
nix develop

# Create a new host (replace 'my-machine' with your hostname)
nix run .#new-host my-machine
```

This creates:
- `hosts/my-machine/default.nix` - Main configuration
- `hosts/my-machine/hardware-configuration.nix` - Hardware settings

## Step 4: Get Your Hardware Configuration

On your NixOS machine:

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/hardware.nix
```

Copy the contents of `/tmp/hardware.nix` into `hosts/my-machine/hardware-configuration.nix`.

## Step 5: Configure Your Host

Edit `hosts/my-machine/default.nix`:

```nix
{ config, lib, pkgs, hostname, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network
  networking.networkmanager.enable = true;

  # Locale
  time.timeZone = "America/New_York";  # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # Your user account
  users.users.yourname = {  # Change 'yourname'
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "wheel" "networkmanager" ];
    # Generate with: mkpasswd -m sha-512
    # hashedPassword = "...";
  };

  # Allow unfree packages (for Steam, Discord, etc.)
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";  # Don't change this
}
```

## Step 6: Choose Your Roles

Edit [parts/hosts.nix](parts/hosts.nix):

```nix
{ inputs, self, ... }:
{
  flake.nixosConfigurations = {
    my-machine = self.lib.mkSystem {
      hostname = "my-machine";
      roles = [
        # Pick roles that fit your use case:
        "gaming"         # Steam, Discord, gaming tools
        "development"    # Git, Docker, IDEs, languages
        "niri-desktop"   # Desktop environment
        # "server"       # SSH, monitoring (don't mix with desktop)
      ];
    };
  };
}
```

## Step 7: Build Your Configuration

```bash
# From your nixos-config directory
sudo nixos-rebuild switch --flake .#my-machine
```

This will:
1. Build your configuration
2. Activate it
3. Install all packages from your roles

## Step 8: Customize

### Adding packages to a role

Edit the role file, e.g., `modules/roles/development.nix`:

```nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Existing packages...

    # Add your custom packages
    jetbrains.idea-community
    postman
  ];
}
```

### Creating a custom role

```bash
nix run .#new-role media-center
```

Edit `modules/roles/media-center.nix`:

```nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    kodi
    plex
    jellyfin
  ];

  services.jellyfin.enable = true;
}
```

Register it in `modules/roles/default.nix`:

```nix
roleModules = {
  gaming = import ./gaming.nix;
  development = import ./development.nix;
  niri-desktop = import ./niri-desktop.nix;
  server = import ./server.nix;
  media-center = import ./media-center.nix;  # Add this line
};
```

## Step 9: Managing Multiple Hosts

Add more hosts to [parts/hosts.nix](parts/hosts.nix):

```nix
{
  flake.nixosConfigurations = {
    # Your desktop
    gaming-rig = self.lib.mkSystem {
      hostname = "gaming-rig";
      roles = [ "gaming" "development" ];
    };

    # Your laptop
    laptop = self.lib.mkSystem {
      hostname = "laptop";
      roles = [ "development" "niri-desktop" ];
    };

    # Your server
    homeserver = self.lib.mkSystem {
      hostname = "homeserver";
      roles = [ "server" ];
    };
  };
}
```

Build specific host:
```bash
sudo nixos-rebuild switch --flake .#laptop
```

## Step 10: Explore Visually

```bash
nix run .#role-explorer
```

Open http://localhost:8080 to see:
- All available roles
- All configured hosts
- Which roles are applied to which hosts

## Common Workflows

### Update your system

```bash
# Update flake inputs
nix flake update

# Rebuild with updates
sudo nixos-rebuild switch --flake .#my-machine
```

### Test changes without activating

```bash
nixos-rebuild build --flake .#my-machine
```

### Rollback if something breaks

```bash
sudo nixos-rebuild switch --rollback
```

### Clean old generations

```bash
sudo nix-collect-garbage -d
```

## Best Practices

1. **Commit often**: Track your config in Git
2. **Test in VM**: Use `nixos-rebuild build-vm` to test major changes
3. **Keep roles focused**: One role = one purpose
4. **Document changes**: Add comments to your configs
5. **Backup**: Keep your flake in version control

## Next Steps

- Read the [README](README.md) for advanced usage
- Explore existing roles in `modules/roles/`
- Check out [NixOS options search](https://search.nixos.org/options)
- Join the NixOS community on Discord/Matrix

## Getting Help

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Nix Pills: https://nixos.org/guides/nix-pills/
- NixOS Discourse: https://discourse.nixos.org/
- NixOS Wiki: https://nixos.wiki/

Happy NixOS-ing! 🚀
