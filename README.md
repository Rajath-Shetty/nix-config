# NixOS Role-Based Configuration System

A production-ready, role-based NixOS configuration system using flakes and flake-parts for clean multi-host management.

## Features

- **Role-Based Configuration**: Tag hosts with roles like `gaming`, `development`, `niri-desktop`, `server` instead of managing individual packages
- **Multi-Host Management**: Manage all your NixOS systems from a single flake
- **Clean Organization**: Using flake-parts for modular structure
- **Bootstrap Script**: Easy conversion of fresh NixOS installs
- **Progressive Web App**: Installable web GUI for exploring roles and hosts (works offline!)
- **Template Generators**: Quick creation of new roles and hosts

## Quick Start

### 1. Clone this repository

```bash
git clone <your-repo-url> nixos-config
cd nixos-config
```

### 2. Enter development environment

```bash
nix develop
```

### 3. Create a new host

```bash
nix run .#new-host my-laptop
```

This creates a new host configuration in `hosts/my-laptop/`. Edit the files to match your system.

### 4. Register the host

Edit [parts/hosts.nix](parts/hosts.nix) and add:

```nix
my-laptop = self.lib.mkSystem {
  hostname = "my-laptop";
  roles = [ "development" "niri-desktop" ];
};
```

### 5. Build and activate

```bash
sudo nixos-rebuild switch --flake .#my-laptop
```

## Directory Structure

```
nixos-config/
├── flake.nix                   # Main flake entry point
├── parts/                      # flake-parts modules
│   ├── hosts.nix              # Host definitions
│   ├── packages.nix           # Utility packages
│   └── shells.nix             # Development shell
├── lib/                        # Helper functions
│   ├── default.nix
│   └── mkSystem.nix           # System builder
├── modules/
│   └── roles/                 # Role definitions
│       ├── default.nix        # Role system
│       ├── gaming.nix
│       ├── development.nix
│       ├── niri-desktop.nix
│       └── server.nix
├── hosts/                      # Per-host configurations
│   ├── gaming-rig/
│   ├── dev-laptop/
│   └── homeserver/
└── README.md
```

## Available Roles

### `gaming`
Steam, Discord, GameMode, graphics drivers, audio setup

### `development`
Git, Docker, VSCode, programming languages, terminal tools

### `niri-desktop`
Niri compositor (scrollable tiling), Wayland, desktop applications

### `server`
SSH, monitoring, automatic updates, security hardening

## Usage

### Create a new role

```bash
nix run .#new-role media-server
```

Then edit `modules/roles/media-server.nix` and register it in `modules/roles/default.nix`.

### Create a new host

```bash
nix run .#new-host office-pc
```

### Explore roles with the PWA

```bash
nix run .#role-explorer
```

Then open http://localhost:8080 in your browser.

**✨ Install as an App:**
1. Click the "Install" button in the browser prompt
2. Or use your browser's "Install App" option (Chrome: ⋮ → Install App)
3. Launch it like any native app!
4. Works offline after first load

The PWA features:
- Modern dark UI with gradient cards
- Real-time role and host information
- Auto-refresh every 30 seconds
- Installable to desktop/home screen
- Offline support via service worker

### Bootstrap a fresh install

On a fresh NixOS installation:

```bash
nix run github:yourusername/nixos-config#bootstrap github:yourusername/nixos-config my-laptop
```

## Example Host Configuration

```nix
# parts/hosts.nix
{
  flake.nixosConfigurations = {
    my-gaming-pc = self.lib.mkSystem {
      hostname = "my-gaming-pc";
      roles = [ "gaming" "development" ];
    };

    my-server = self.lib.mkSystem {
      hostname = "my-server";
      roles = [ "server" ];
      system = "aarch64-linux";  # ARM server
    };
  };
}
```

## Customization

### Adding packages to a role

Edit the role file in `modules/roles/`:

```nix
# modules/roles/gaming.nix
{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    steam
    discord
    # Add more packages...
  ];
}
```

### Host-specific configuration

Edit the host's `default.nix`:

```nix
# hosts/my-laptop/default.nix
{ config, lib, pkgs, hostname, ... }:
{
  # This runs ONLY on this host
  services.tlp.enable = true;  # Laptop power management
}
```

## Tips

- Keep hardware-configuration.nix separate per host
- Use roles for shared configuration
- Use host configs for machine-specific settings
- Run `nix flake check` to validate your configuration
- Use `nixos-rebuild build --flake .#hostname` to test without activating

## Updating

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Rebuild with updates
sudo nixos-rebuild switch --flake .#hostname
```

## Troubleshooting

### "error: getting status of '/nix/store/...': No such file or directory"

Run `nix flake check` to validate your configuration.

### "attribute 'nixosConfigurations.hostname' missing"

Make sure your host is registered in [parts/hosts.nix](parts/hosts.nix).

### Role not applying

Check that:
1. The role is listed in your host's `roles = [ ... ]`
2. The role is imported in [modules/roles/default.nix](modules/roles/default.nix)

## Contributing

1. Create a new role or improve existing ones
2. Test with `nixos-rebuild build`
3. Submit a PR

## License

MIT
# nix-config
