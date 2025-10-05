{ self, inputs, ... }:

{
  perSystem = { config, system, pkgs, ... }:
    let
      # Documentation package
      docs = pkgs.stdenv.mkDerivation {
        name = "nixos-config-docs";
        src = ../.;
        installPhase = ''
          mkdir -p $out/share/nixos-config
          cp README.md $out/share/nixos-config/
          cp GETTING_STARTED.md $out/share/nixos-config/
          cp DEV_ENVIRONMENTS.md $out/share/nixos-config/
          cp FRESH_INSTALL.md $out/share/nixos-config/
          mkdir -p $out/share/nixos-config/webapp
          cp webapp/README.md $out/share/nixos-config/webapp/
        '';
      };

      # Documentation viewer script
      docs-viewer = pkgs.substituteAll {
        src = ./docs-viewer.sh;
        docsDir = "${docs}/share/nixos-config";
      };
    in
    {
      packages = {
        # Documentation viewer
        nixos-docs = pkgs.writeShellScriptBin "nixos-docs" (builtins.readFile docs-viewer);

        # Alias for convenience
        nixos-help = pkgs.writeShellScriptBin "nixos-help" ''
          exec ${pkgs.writeShellScriptBin "nixos-docs" (builtins.readFile docs-viewer)}/bin/nixos-docs "$@"
        '';

      # Bootstrap script for fresh NixOS installs
      bootstrap = pkgs.writeShellScriptBin "nixos-bootstrap" ''
        #!/usr/bin/env bash
        set -euo pipefail

        FLAKE_URL="''${1:-}"
        HOSTNAME="''${2:-}"

        if [ -z "$FLAKE_URL" ] || [ -z "$HOSTNAME" ]; then
          echo "Usage: nixos-bootstrap <flake-url> <hostname>"
          echo "Example: nixos-bootstrap github:yourusername/nixos-config gaming-rig"
          exit 1
        fi

        echo "==> Bootstrapping NixOS with role-based configuration"
        echo "    Flake: $FLAKE_URL"
        echo "    Hostname: $HOSTNAME"

        # Ensure we're on NixOS
        if [ ! -f /etc/NIXOS ]; then
          echo "Error: This script must be run on NixOS"
          exit 1
        fi

        # Backup existing configuration
        if [ -d /etc/nixos ]; then
          echo "==> Backing up existing configuration"
          sudo cp -r /etc/nixos /etc/nixos.backup-$(date +%Y%m%d-%H%M%S)
        fi

        # Create hardware configuration if it doesn't exist
        if [ ! -f /etc/nixos/hardware-configuration.nix ]; then
          echo "==> Generating hardware configuration"
          sudo nixos-generate-config
        fi

        # Build and switch to new configuration
        echo "==> Building NixOS configuration"
        sudo nixos-rebuild switch --flake "$FLAKE_URL#$HOSTNAME"

        echo "==> Bootstrap complete!"
        echo "    Your system has been configured with the role-based setup"
      '';

      # Role explorer web GUI
      role-explorer = pkgs.writeShellScriptBin "role-explorer" ''
        #!/usr/bin/env bash
        set -euo pipefail

        PORT=''${PORT:-8080}

        echo "Starting role explorer on http://localhost:$PORT"
        ${pkgs.python3}/bin/python3 ${./role-explorer.py} "$PORT"
      '';

      # Template generator for new roles
      new-role = pkgs.writeShellScriptBin "new-role" ''
        #!/usr/bin/env bash
        set -euo pipefail

        ROLE_NAME="''${1:-}"

        if [ -z "$ROLE_NAME" ]; then
          echo "Usage: new-role <role-name>"
          echo "Example: new-role gaming"
          exit 1
        fi

        ROLE_FILE="modules/roles/$ROLE_NAME.nix"

        if [ -f "$ROLE_FILE" ]; then
          echo "Error: Role '$ROLE_NAME' already exists at $ROLE_FILE"
          exit 1
        fi

        cat > "$ROLE_FILE" << 'EOF'
        { config, lib, pkgs, ... }:

        {
          # Packages for this role
          environment.systemPackages = with pkgs; [
            # Add packages here
          ];

          # Services for this role
          # systemd.services = {};

          # Programs for this role
          # programs = {};

          # Additional configuration
        }
        EOF

        echo "Created new role at $ROLE_FILE"
        echo "Don't forget to add it to modules/roles/default.nix!"
      '';

      # Template generator for new hosts
      new-host = pkgs.writeShellScriptBin "new-host" ''
        #!/usr/bin/env bash
        set -euo pipefail

        HOSTNAME="''${1:-}"

        if [ -z "$HOSTNAME" ]; then
          echo "Usage: new-host <hostname>"
          echo "Example: new-host my-laptop"
          exit 1
        fi

        HOST_DIR="hosts/$HOSTNAME"

        if [ -d "$HOST_DIR" ]; then
          echo "Error: Host '$HOSTNAME' already exists at $HOST_DIR"
          exit 1
        fi

        mkdir -p "$HOST_DIR"

        cat > "$HOST_DIR/default.nix" << 'EOF'
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
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
            # hashedPassword = ""; # Set this
          };

          # Allow unfree packages if needed
          # nixpkgs.config.allowUnfree = true;

          system.stateVersion = "24.05";
        }
        EOF

        cat > "$HOST_DIR/hardware-configuration.nix" << 'EOF'
        # This is a placeholder. Run nixos-generate-config and copy the result here.
        { config, lib, pkgs, ... }:

        {
          boot.initrd.availableKernelModules = [ ];
          boot.initrd.kernelModules = [ ];
          boot.kernelModules = [ ];
          boot.extraModulePackages = [ ];

          fileSystems."/" = {
            device = "/dev/disk/by-label/nixos";
            fsType = "ext4";
          };

          # Add your actual hardware configuration here
        }
        EOF

        echo "Created new host at $HOST_DIR"
        echo "Don't forget to:"
        echo "  1. Add hardware configuration to $HOST_DIR/hardware-configuration.nix"
        echo "  2. Register it in parts/hosts.nix"
      '';

      # Documentation package (for installation into system)
      inherit docs;

      # mdBook documentation server
      docs-serve = pkgs.writeShellScriptBin "nixos-docs-serve" ''
        #!/usr/bin/env bash
        set -euo pipefail

        PORT=''${1:-3000}

        if [ ! -d "docs" ]; then
          echo "Error: Run this from your nixos-config directory"
          exit 1
        fi

        echo "📚 Building documentation..."
        ${pkgs.mdbook}/bin/mdbook build docs

        echo "🌐 Serving documentation at http://localhost:$PORT"
        echo "   Press Ctrl+C to stop"
        ${pkgs.python3}/bin/python3 -m http.server $PORT -d docs/book
      '';

      # mdBook documentation builder
      docs-build = pkgs.writeShellScriptBin "nixos-docs-build" ''
        #!/usr/bin/env bash
        set -euo pipefail

        if [ ! -d "docs" ]; then
          echo "Error: Run this from your nixos-config directory"
          exit 1
        fi

        echo "📚 Building documentation..."
        ${pkgs.mdbook}/bin/mdbook build docs

        echo "✅ Documentation built to docs/book/"
        echo "   Open docs/book/index.html in your browser"
      '';
    };
  };
}
