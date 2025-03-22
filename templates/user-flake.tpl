{
  description = "{{ TARGET_USER | capitalize }} at {{ TARGET_MACHINE | capitalize }} home-manager Configuration";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    casitas = {
      url = "git+ssh://git@github.com/judiantara/casitas";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, casitas, ... }:
  let
    user = "{{ TARGET_USER }}";
    hostname = "{{ TARGET_MACHINE }}";

    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations = {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      "${user}" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        # Optionally use extraSpecialArgs
        # to pass through arguments to home.nix
        extraSpecialArgs = {
          user     = "${user}";
          hostname = "${hostname}";
        };

        modules = casitas.nixosModules."${user}@${hostname}";
      };
    };
  };
}
