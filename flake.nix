{
  description = "Wyvern the NixOS installer";

  inputs = {
    nixpkgs = {
      #url = "github:nixos/nixpkgs/nixos-unstable";
      url = "github:NixOS/nixpkgs/nixos-25.11";
    };
  };

  outputs = {self, nixpkgs, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit (self) inputs outputs;
      };

      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./config
      ];
    };
  };
}
