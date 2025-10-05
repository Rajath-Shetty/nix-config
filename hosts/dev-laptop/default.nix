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
  users.users.dev = {
    isNormalUser = true;
    description = "Developer";
    extraGroups = [ "wheel" "networkmanager" ];
    # hashedPassword = ""; # Set this with: mkpasswd -m sha-512
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Laptop-specific: Enable TLP for battery management
  services.tlp.enable = true;

  # Laptop-specific: Enable touchpad support
  services.xserver.libinput.enable = true;

  system.stateVersion = "24.05";
}
