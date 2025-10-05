# Fresh NixOS Install Guide

This guide explains how to bootstrap a fresh NixOS installation with this role-based configuration system.

## Method 1: Direct Bootstrap (Recommended)

On a fresh NixOS install with internet connection:

### Step 1: Ensure Git is available

```bash
nix-shell -p git
```

### Step 2: Clone your configuration

```bash
# If you've already pushed to GitHub/GitLab
git clone https://github.com/yourusername/nixos-config /etc/nixos-new

# Or if working locally, copy your config
# scp -r your-machine:/path/to/nixos-config /etc/nixos-new
```

### Step 3: Get hardware configuration

```bash
sudo nixos-generate-config --show-hardware-config > /tmp/hardware.nix
```

### Step 4: Create your host configuration

```bash
cd /etc/nixos-new

# Create host directory
mkdir -p hosts/$(hostname)

# Copy hardware config
cp /tmp/hardware.nix hosts/$(hostname)/hardware-configuration.nix
```

### Step 5: Create host default.nix

Create `hosts/$(hostname)/default.nix`:

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
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # User (change this!)
  users.users.yourname = {
    isNormalUser = true;
    description = "Your Name";
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "changeme";  # Change on first login!
  };

  # Allow unfree if needed
  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "24.05";
}
```

### Step 6: Register host in flake

Edit `parts/hosts.nix` and add:

```nix
{
  flake.nixosConfigurations = {
    # ... existing hosts ...

    "$(hostname)" = self.lib.mkSystem {
      hostname = "$(hostname)";
      roles = [ "development" ];  # Choose your roles
    };
  };
}
```

### Step 7: Build and switch

```bash
cd /etc/nixos-new
sudo nixos-rebuild switch --flake .#$(hostname)
```

### Step 8: Move to permanent location (optional)

```bash
sudo mv /etc/nixos /etc/nixos.backup
sudo mv /etc/nixos-new /etc/nixos
cd /etc/nixos
```

## Method 2: Using the Bootstrap Script

If your config is already on GitHub:

```bash
# From NixOS installer
nix run github:yourusername/nixos-config#bootstrap github:yourusername/nixos-config your-hostname
```

**Note**: You'll still need to:
1. Edit the generated config to add your user
2. Copy hardware-configuration.nix
3. Register the host in parts/hosts.nix

## Method 3: Installation Media with Built-in Config

For the most automated experience, you can create a custom NixOS ISO with your config pre-loaded.

### Step 1: Create installer configuration

Create `installer.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  # Include your flake in the ISO
  environment.systemPackages = [ pkgs.git ];

  # Pre-clone your config
  system.activationScripts.preloadConfig = ''
    mkdir -p /root/nixos-config
    ${pkgs.git}/bin/git clone https://github.com/yourusername/nixos-config /root/nixos-config
  '';
}
```

### Step 2: Build ISO

```bash
nix-build '<nixpkgs/nixos>' -A config.system.build.isoImage -I nixos-config=./installer.nix
```

## Common Fresh Install Workflow

```bash
# 1. Boot from NixOS installer

# 2. Partition disks
sudo fdisk /dev/sda  # or use gparted

# 3. Format partitions
sudo mkfs.ext4 -L nixos /dev/sda2
sudo mkfs.fat -F 32 -n boot /dev/sda1

# 4. Mount
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot

# 5. Generate initial config
sudo nixos-generate-config --root /mnt

# 6. Clone your flake
nix-shell -p git
git clone https://github.com/yourusername/nixos-config /mnt/etc/nixos-config

# 7. Copy hardware config
sudo cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos-config/hosts/my-new-host/

# 8. Edit host config
# ... edit /mnt/etc/nixos-config/hosts/my-new-host/default.nix ...
# ... edit /mnt/etc/nixos-config/parts/hosts.nix to register host ...

# 9. Install
sudo nixos-install --flake /mnt/etc/nixos-config#my-new-host

# 10. Reboot
sudo reboot
```

## Post-Install

After booting into your new system:

### 1. Set user password

```bash
passwd yourname
```

### 2. Clone config to your home

```bash
cd ~
git clone https://github.com/yourusername/nixos-config
```

### 3. Make changes and rebuild

```bash
cd ~/nixos-config
# Make changes...
sudo nixos-rebuild switch --flake .#$(hostname)
```

### 4. Commit and push

```bash
git add .
git commit -m "Add $(hostname) configuration"
git push
```

## Troubleshooting

### "experimental features not enabled"

Add to `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

### Can't find host configuration

Make sure:
1. Host directory exists: `hosts/your-hostname/`
2. Host is registered in `parts/hosts.nix`
3. Flake is in `/etc/nixos` or use full path with `--flake`

### Hardware config issues

Always generate fresh on the target hardware:
```bash
sudo nixos-generate-config --show-hardware-config
```

### Missing packages

Check that your roles are enabled in `parts/hosts.nix`:
```nix
roles = [ "development" "gaming" ];
```

## Tips

- **Start minimal**: Use basic roles first, add more later
- **Test in VM**: Use `nixos-rebuild build-vm` to test
- **Keep it in git**: Commit every working change
- **Document hardware**: Note any special hardware requirements

## Emergency Recovery

If your system won't boot:

1. Boot from NixOS installer
2. Mount your system
3. Chroot in:
   ```bash
   sudo mount /dev/disk/by-label/nixos /mnt
   sudo mount /dev/disk/by-label/boot /mnt/boot
   sudo nixos-enter --root /mnt
   ```
4. Fix config and rebuild
5. Reboot

Or rollback to previous generation from GRUB boot menu.
