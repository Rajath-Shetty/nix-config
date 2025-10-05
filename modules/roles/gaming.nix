{ config, lib, pkgs, ... }:

{
  # Gaming packages
  environment.systemPackages = with pkgs; [
    steam
    discord
    lutris
    wine
    winetricks
    gamemode
    mangohud
  ];

  # Enable Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Enable GameMode
  programs.gamemode.enable = true;

  # Graphics drivers (adjust based on your hardware)
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Audio for gaming
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Performance tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # For some games
  };
}
