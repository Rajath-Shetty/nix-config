{ config, lib, pkgs, ... }:

lib.mkIf config.roles.niri-desktop {
  # Niri compositor (scrollable tiling)
  # Note: Niri might need to be added from nixpkgs unstable or custom overlay

  # Display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --cmd niri-session";
      };
    };
  };

  # Essential desktop packages
  environment.systemPackages = with pkgs; [
    # Niri (you may need to add this from an overlay or build from source)
    # niri

    # Terminal
    alacritty
    kitty

    # Application launcher
    fuzzel
    rofi-wayland

    # File manager
    nautilus

    # Web browser
    firefox

    # Media
    mpv

    # Screenshots
    grim
    slurp

    # Notifications
    mako

    # System monitoring
    htop
    btop

    # Clipboard
    wl-clipboard

    # Fonts
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
  ];

  # Wayland support
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
  };

  # XDG portal for screen sharing, file picking, etc.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
  ];
}
