{
  description = "Wyvern the NixOS installer";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      #url = "github:NixOS/nixpkgs/nixos-24.11";
    };
  };

  outputs = {self, nixpkgs, ... }@inputs: let
    system    = "x86_64-linux";
    pkgs      = import nixpkgs { inherit system; };
    
    pbkdf2-sha512 = pkgs.callPackage ./pbkdf2-sha512 { };
    
    rbtohex = pkgs.writeShellScriptBin
      "rbtohex"
     (builtins.readFile ./scripts/rbtohex.sh);

    hextorb = pkgs.writeShellScriptBin
      "hextorb"
     (builtins.readFile ./scripts/hextorb.sh);

    yk-luks-gen = pkgs.writeShellScriptBin 
     "yk-luks-gen" 
     (builtins.readFile ./scripts/yk-luks-gen.sh);

    run-installer = pkgs.writeShellScriptBin 
     "run-installer" 
     (builtins.readFile ./scripts/run-installer.sh);

    run-ssh-patcher = pkgs.writeShellScriptBin 
     "run-ssh-patcher" 
     (builtins.readFile ./scripts/run-ssh-patcher.sh);

  in {
    devShells.${system} = {
      run-ssh-patcher = pkgs.mkShell {
        packages = with pkgs; [
          rage
          run-ssh-patcher
        ];
        shellHook = ''
          exec run-ssh-patcher
        '';
      };
  
      run-installer = pkgs.mkShell {
        packages = with pkgs; [
          rage
          disko
          cryptsetup
          openssl
          parted
          yubikey-personalization
          tera-cli
          pbkdf2-sha512
          rbtohex
          hextorb
          yk-luks-gen
          run-installer
        ];
        shellHook = ''
          exec run-installer
        '';
      };
    };
  };
}
