{ config, lib, ... }:

{
  options.roles = {
    gaming = lib.mkEnableOption "gaming role";
    development = lib.mkEnableOption "development role";
    niri-desktop = lib.mkEnableOption "niri-desktop role";
    server = lib.mkEnableOption "server role";
  };

  imports = [
    ./gaming.nix
    ./development.nix
    ./niri-desktop.nix
    ./server.nix
  ];
}
