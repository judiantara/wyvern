{
  description = "Seiryu NixOS Machines Configuration";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };

    wyrmling = {
      url = "github:judiantara/wyrmling";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, wyrmling, ... }:
  let
    system   = "x86_64-linux";
    hostname = "seiryu";
    user     = "pemweb";
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
