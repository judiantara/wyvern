{
  description = "{{ TARGET_MACHINE }} NixOS Machines Configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
      #url = "github:NixOS/nixpkgs/nixos-24.11";
    };

    wyrmling = {
      url = "github:judiantara/wyrmling";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, wyrmling, ... }:
  let
    systems = [
        "x86_64-linux"
    ];

    user     = "{{ TARGET_USER }}";
    hostname = "{{ TARGET_MACHINE }}";

    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    nixosConfigurations = {
      "${hostname}" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit (self) inputs outputs;
          hostname = "${hostname}";
          user     = "${user}";
        };

        modules = wyrmling.nixosModules."${hostname}";
      };
    };
  };
}
