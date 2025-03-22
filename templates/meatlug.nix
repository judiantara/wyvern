{
  description = "Meatlug NixOS Machines Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    wyrmling = {
      url = "github:judiantara/wyrmling";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, wyrmling, ... }:
  let
    system   = "x86_64-linux";
    hostname = "meatlug";
    user     = "judiantara";
  in {
    nixosConfigurations = {
      "${hostname}" = nixpkgs.lib.nixosSystem {
        system = "${system}"; 
        specialArgs = {
          inherit (self) inputs outputs;
          hostname = "${hostname}";
          user     = "${user}";
        };

        modules = wyrmling.nixosModules."${hostname}";
    };
  };
}
