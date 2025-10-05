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
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # Users
  users.users.admin = {
    isNormalUser = true;
    description = "Server Admin";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Add your SSH public keys here
      # "ssh-ed25519 AAAAC3... user@host"
    ];
  };

  # Server-specific: Disable X11
  services.xserver.enable = false;

  # Server-specific: No GUI packages
  environment.noXlibs = true;

  system.stateVersion = "24.05";
}
