{ config, lib, pkgs, ... }:

lib.mkIf config.roles.development {
  # Development tools
  environment.systemPackages = with pkgs; [
    # Version control
    git
    gh # GitHub CLI

    # Editors
    vim
    neovim
    vscode

    # Build tools
    gcc
    gnumake
    cmake

    # Languages
    python3
    nodejs
    go
    rustc
    cargo

    # Container tools
    docker-compose

    # Terminal tools
    tmux
    zellij
    ripgrep
    fd
    bat
    eza
    fzf
    direnv
    nix-direnv

    # Development utilities
    jq
    yq
    httpie

    # Documentation
    man-pages
    tldr
    mdbook  # For building documentation
  ];

  # Enable direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Bash integration
  programs.bash.interactiveShellInit = ''
    eval "$(direnv hook bash)"
  '';

  # Zsh integration (if you use zsh)
  # programs.zsh.interactiveShellInit = ''
  #   eval "$(direnv hook zsh)"
  # '';

  # Fish integration (if you use fish)
  # programs.fish.interactiveShellInit = ''
  #   direnv hook fish | source
  # '';

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Enable PostgreSQL (optional, uncomment if needed)
  # services.postgresql = {
  #   enable = true;
  #   package = pkgs.postgresql_15;
  # };

  # Note: Users need to manually add "docker" to their extraGroups
  # Or you can do it in your host configuration like:
  # users.users.youruser.extraGroups = [ "wheel" "networkmanager" "docker" ];
}
