{ config, lib, pkgs, inputs, ... }:

{
  # Add documentation tools to system packages
  environment.systemPackages = with pkgs; [
    # Documentation viewers (optional but recommended)
    glow  # Markdown viewer
    bat   # Syntax-highlighted cat
    fzf   # For interactive mode
  ];

  # Install documentation command
  # This will be available system-wide
  environment.systemPackages = lib.mkIf (inputs ? self) [
    inputs.self.packages.${pkgs.system}.nixos-docs
    inputs.self.packages.${pkgs.system}.nixos-help
  ];

  # Add docs to system help
  documentation.man.enable = lib.mkDefault true;

  # Show helpful message on login
  environment.interactiveShellInit = ''
    # Show docs hint on first login
    if [ ! -f ~/.config/nixos-docs-shown ]; then
      echo "💡 Tip: Run 'nixos-docs' to view system documentation"
      echo "   Try: nixos-docs overview, nixos-docs dev, nixos-docs roles"
      mkdir -p ~/.config
      touch ~/.config/nixos-docs-shown
    fi
  '';
}
