{ config, lib, pkgs, ... }:

let
  cfg = config.roles;

  # Import all role modules
  roleModules = {
    gaming = import ./gaming.nix;
    development = import ./development.nix;
    niri-desktop = import ./niri-desktop.nix;
    server = import ./server.nix;
  };

in
{
  options.roles = {
    enable = lib.mkOption {
      type = lib.types.listOf (lib.types.enum (builtins.attrNames roleModules));
      default = [ ];
      description = "List of roles to enable for this system";
      example = [ "gaming" "development" ];
    };

    available = lib.mkOption {
      type = lib.types.attrsOf lib.types.unspecified;
      default = roleModules;
      readOnly = true;
      description = "Available role modules";
    };
  };

  imports = map (roleName: roleModules.${roleName}) cfg.enable;
}
