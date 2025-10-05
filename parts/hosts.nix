{ inputs, self, ... }:

{
  flake.nixosConfigurations = {
    # Example gaming desktop
    gaming-rig = self.lib.mkSystem {
      hostname = "gaming-rig";
      roles = [ "gaming" "development" ];
    };

    # Example development laptop
    dev-laptop = self.lib.mkSystem {
      hostname = "dev-laptop";
      roles = [ "development" "niri-desktop" ];
    };

    # Example server
    homeserver = self.lib.mkSystem {
      hostname = "homeserver";
      roles = [ "server" ];
    };

    # Add more hosts here...
  };
}
