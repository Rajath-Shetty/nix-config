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
      docs-viewer = pkgs.replaceVars ./docs-viewer.sh {
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
        HOSTNAME="''${2:-$(hostname)}"

        if [ -z "$FLAKE_URL" ]; then
          echo "Usage: nixos-bootstrap <flake-url> [hostname]"
          echo ""
          echo "Examples:"
          echo "  nixos-bootstrap github:yourusername/nixos-config"
          echo "  nixos-bootstrap github:yourusername/nixos-config my-laptop"
          echo "  nixos-bootstrap . my-laptop  (if already cloned)"
          exit 1
        fi

        echo "╔════════════════════════════════════════════╗"
        echo "║  NixOS Role-Based Configuration Bootstrap ║"
        echo "╚════════════════════════════════════════════╝"
        echo ""
        echo "Flake:    $FLAKE_URL"
        echo "Hostname: $HOSTNAME"
        echo ""

        # Ensure we're on NixOS
        if [ ! -f /etc/NIXOS ]; then
          echo "❌ Error: This script must be run on NixOS"
          exit 1
        fi

        # Backup existing configuration
        if [ -d /etc/nixos ]; then
          BACKUP="/etc/nixos.backup-$(date +%Y%m%d-%H%M%S)"
          echo "📦 Backing up existing /etc/nixos to $BACKUP"
          sudo mv /etc/nixos "$BACKUP"
        fi

        # Clone or copy the flake
        echo ""
        echo "📥 Fetching configuration..."
        if [[ "$FLAKE_URL" == "." ]] || [[ "$FLAKE_URL" == /* ]]; then
          # Local path
          echo "   Copying from local path: $FLAKE_URL"
          sudo cp -r "$FLAKE_URL" /etc/nixos
        else
          # Remote URL
          echo "   Cloning from: $FLAKE_URL"
          sudo ${pkgs.git}/bin/git clone "$FLAKE_URL" /etc/nixos
        fi

        # Generate hardware configuration
        echo ""
        echo "🔧 Generating hardware configuration..."
        sudo ${pkgs.nixos-generate-config}/bin/nixos-generate-config --show-hardware-config > /tmp/hardware.nix

        # Check if host exists
        if [ ! -d "/etc/nixos/hosts/$HOSTNAME" ]; then
          echo ""
          echo "⚠️  Host '$HOSTNAME' not found in configuration!"
          echo "   Creating new host configuration..."

          sudo mkdir -p "/etc/nixos/hosts/$HOSTNAME"
          sudo cp /tmp/hardware.nix "/etc/nixos/hosts/$HOSTNAME/hardware-configuration.nix"

          # Create minimal default.nix
          sudo tee "/etc/nixos/hosts/$HOSTNAME/default.nix" > /dev/null << 'HOSTEOF'
{ config, lib, pkgs, hostname, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "nixos";
  };

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05";
}
HOSTEOF

          echo ""
          echo "⚠️  IMPORTANT: You need to register this host in parts/hosts.nix"
          echo "   Add this to flake.nixosConfigurations:"
          echo ""
          echo "   $HOSTNAME = self.lib.mkSystem {"
          echo "     hostname = \"$HOSTNAME\";"
          echo "     roles = [ \"development\" ];"
          echo "   };"
          echo ""
          read -p "Press Enter to continue with default configuration, or Ctrl+C to abort and configure manually..."
        else
          # Host exists, update hardware config
          echo "   Updating hardware configuration for $HOSTNAME..."
          sudo cp /tmp/hardware.nix "/etc/nixos/hosts/$HOSTNAME/hardware-configuration.nix"
        fi

        # Build and switch
        echo ""
        echo "🔨 Building NixOS configuration..."
        sudo nixos-rebuild switch --flake "/etc/nixos#$HOSTNAME"

        echo ""
        echo "╔════════════════════════════════════════════╗"
        echo "║        ✅ Bootstrap Complete! ✅           ║"
        echo "╚════════════════════════════════════════════╝"
        echo ""
        echo "Your system has been configured with:"
        echo "  • Role-based NixOS configuration"
        echo "  • Configuration stored in /etc/nixos"
        echo "  • Host: $HOSTNAME"
        echo ""
        echo "Next steps:"
        echo "  cd /etc/nixos"
        echo "  nix run .#role-explorer    # Explore your config"
        echo "  nixos-docs                 # View documentation"
        echo ""
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
