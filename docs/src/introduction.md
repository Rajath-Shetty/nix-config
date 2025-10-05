# Introduction

Welcome to the **NixOS Role-Based Configuration System**!

This is a production-ready, modern approach to managing NixOS systems using **roles** instead of individual package lists.

## What is This?

Instead of writing this for every host:

```nix
environment.systemPackages = [
  steam discord nvidia-driver gamemode wine lutris
  git docker vscode python nodejs rust cargo
  # ... hundreds more
];
```

You write this:

```nix
roles = [ "gaming" "development" ];
```

## Key Features

- ✅ **Role-Based**: Tag hosts with roles like `gaming`, `development`, `server`
- ✅ **Multi-Host**: Manage all your systems from one flake
- ✅ **Dev Environments**: Per-project dev shells with direnv
- ✅ **Web GUI**: Progressive Web App for exploring your config
- ✅ **Templates**: Quick-start templates for new roles and hosts
- ✅ **Production-Ready**: Used in real deployments

## Quick Example

```nix
# parts/hosts.nix
{
  gaming-pc = mkSystem {
    hostname = "gaming-pc";
    roles = [ "gaming" "development" ];
  };

  laptop = mkSystem {
    hostname = "laptop";
    roles = [ "development" "niri-desktop" ];
  };

  homeserver = mkSystem {
    hostname = "homeserver";
    roles = [ "server" ];
  };
}
```

Then:

```bash
sudo nixos-rebuild switch --flake .#gaming-pc
```

## Next Steps

- [Quick Start](./quick-start.md) - Get started in 5 minutes
- [Role System](./roles/README.md) - Learn about roles
- [Dev Environments](./dev/README.md) - Set up per-project environments

Let's go! 🚀
