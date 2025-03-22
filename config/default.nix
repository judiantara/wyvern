{ pkgs, lib, ... }:

{
  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    extraOptions = "experimental-features = nix-command flakes";
    channel.enable = false;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems = lib.mkForce ["btrfs" "vfat" "f2fs" "xfs" "ntfs"];
  };

  networking = {
    hostName = "installer";
  };

  systemd = {
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };

  environment.systemPackages = let
    key-vault       = pkgs.callPackage ../packages/key-vault { };
    pbkdf2-sha512   = pkgs.callPackage ../packages/pbkdf2-sha512 { };

    rbtohex         = pkgs.writeShellScriptBin "rbtohex"         (builtins.readFile ../packages/scripts/rbtohex.sh);
    hextorb         = pkgs.writeShellScriptBin "hextorb"         (builtins.readFile ../packages/scripts/hextorb.sh);
    yk-luks-gen     = pkgs.writeShellScriptBin "yk-luks-gen"     (builtins.readFile ../packages/scripts/yk-luks-gen.sh);
    run-installer   = pkgs.writeShellScriptBin "run-installer"   (builtins.readFile ../packages/scripts/run-installer.sh);
    run-ssh-patcher = pkgs.writeShellScriptBin "run-ssh-patcher" (builtins.readFile ../packages/scripts/run-ssh-patcher.sh);
    install-nixos   = pkgs.writeShellScriptBin "install-nixos"   (builtins.readFile ../packages/scripts/install-nixos.sh);
    prep-installer  = pkgs.writeShellScriptBin "prep-installer"  (builtins.readFile ../packages/scripts/prep-installer.sh);

    key-vault-path  = pkgs.writeShellScriptBin "set-key-vault-path" ''

    set -euo pipefail

    export VAULT_DIR="${key-vault}"
    export VAULT_KEY="$VAULT_DIR/wyvern.key.age"
    '';

  in [
    key-vault
    pbkdf2-sha512
    rbtohex
    hextorb
    yk-luks-gen
    run-installer
    run-ssh-patcher
    install-nixos
    prep-installer
    key-vault-path
    pkgs.rage
    pkgs.disko
    pkgs.cryptsetup
    pkgs.openssl
    pkgs.parted
    pkgs.yubikey-personalization
  ];
}
