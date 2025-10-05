{ config, lib, pkgs, ... }:

lib.mkIf config.roles.server {
  # Server packages
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    iotop
    nethogs

    # Networking
    curl
    wget
    rsync

    # System tools
    vim
    tmux
    git
  ];

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ]; # SSH
  };

  # Automatic updates (optional)
  system.autoUpgrade = {
    enable = false; # Set to true to enable auto-updates
    flake = "self";
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # Show build logs
    ];
    dates = "04:00";
  };

  # Prometheus node exporter for monitoring
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
    port = 9100;
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize nix store
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
