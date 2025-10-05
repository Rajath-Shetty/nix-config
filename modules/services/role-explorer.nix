{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.role-explorer;

  role-explorer-script = pkgs.writeShellScriptBin "role-explorer-daemon" ''
    #!${pkgs.bash}/bin/bash
    cd ${config.users.users.${cfg.user}.home}/nixos-config || cd /etc/nixos
    exec ${pkgs.python3}/bin/python3 ${../parts/role-explorer.py} ${toString cfg.port}
  '';

in
{
  options.services.role-explorer = {
    enable = mkEnableOption "Role Explorer web interface";

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to run the role explorer on";
    };

    user = mkOption {
      type = types.str;
      default = "nixos";
      description = "User to run the service as";
    };

    configPath = mkOption {
      type = types.str;
      default = "/etc/nixos";
      description = "Path to the NixOS configuration directory";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.role-explorer = {
      description = "NixOS Role Explorer Web Interface";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${role-explorer-script}/bin/role-explorer-daemon";
        Restart = "always";
        RestartSec = "10s";
        User = cfg.user;
        WorkingDirectory = cfg.configPath;

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadOnlyPaths = [ cfg.configPath ];
      };

      environment = {
        PYTHONUNBUFFERED = "1";
      };
    };

    # Open firewall if needed
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
