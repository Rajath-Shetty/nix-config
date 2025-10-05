{ inputs }:

{ hostname
, system ? "x86_64-linux"
, roles ? [ ]
, extraModules ? [ ]
}:

inputs.nixpkgs.lib.nixosSystem {
  inherit system;

  specialArgs = {
    inherit inputs hostname;
  };

  modules = [
    # Import role system
    ../modules/roles

    # Import documentation system
    ../modules/nixos-docs.nix

    # Set hostname
    { networking.hostName = hostname; }

    # Enable flakes and nix command
    {
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
    }

    # Import host-specific config
    ../hosts/${hostname}

    # Set roles
    {
      roles = inputs.nixpkgs.lib.genAttrs roles (role: true);
    }
  ] ++ extraModules;
}
