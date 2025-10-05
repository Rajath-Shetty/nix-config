{
  description = "Role-based NixOS Configuration System";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Optional: Add home-manager if needed
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];

      imports = [
        ./parts/hosts.nix
        ./parts/packages.nix
        ./parts/shells.nix
      ];

      flake = {
        # Make lib available to all parts
        lib = import ./lib { inherit inputs; };
      };
    };
}
