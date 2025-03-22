{ inputs, pkgs, lib, options, config, ... }:

{
  # disable ssh client
  #options.programs.ssh = lib.mkOption {};

  disabledModules = [
    "services/desktop-managers/plasma6.nix"
  ];

  config = {
    system.stateVersion = "26.05";

    isoImage = {
      squashfsCompression = "xz -Xdict-size 100%";
      makeEfiBootable = true;
      makeUsbBootable = true;
    };

    image.baseName = lib.mkForce "Wyvern-${config.system.stateVersion}";

    documentation.enable = false;
    documentation.doc.enable = false;
    documentation.man.enable = false;
    documentation.nixos.enable = false;

    # Opinionated: solely use flake instead of nix channels
    nix = let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in {
      settings = {
        # Enable flakes and new 'nix' command
        experimental-features = "nix-command flakes";

        # Opinionated: disable global registry
        #flake-registry = "";

        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = config.nix.nixPath;

        download-buffer-size = 524288000;

        substituters = [
          "https://cache.windwalker.opik"
        ];

        trusted-public-keys = [
          "cache.whiteclaw.opik:5YveYTL1HtM7zhifQrSXx0/PYdVeCu1psCYJM7lu6dE="
        ];
      };

      extraOptions = "experimental-features = nix-command flakes";

      # Opinionated: disable channels
      channel.enable = lib.mkForce false;

      # Opinionated: make flake registry and nix path match flake inputs
      registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };

    boot = {
      enableContainers = lib.mkForce false;
      kernelPackages = pkgs.linuxPackages_latest;

      # Mandatory file systems for booting an ISO image
      supportedFilesystems = lib.mkForce ["squashfs" "iso9660" "vfat" "ext4"];


      tmp.useTmpfs = lib.mkForce true;

      #dirty frag mitigation
      extraModprobeConfig = ''
        install esp4 ${pkgs.coreutils}/bin/false
        install esp6 ${pkgs.coreutils}/bin/false
        install rxrpc ${pkgs.coreutils}/bin/false
      '';

      blacklistedKernelModules = [
        "esp4"
        "esp6"
        "rxrpc"
      ];

      kernel.sysctl = {
        "kernel.printk" = "2 4 1 7";
      };

      extraModulePackages = [
      ];

      initrd = {
        #enable systemd on bootloader stage 1
        systemd.enable = true;

        availableKernelModules = [
          "squashfs"
          "iso9660"
          "overlay"
          "nvme"
          "xhci_pci"
          "ahci"
          "usbhid"
          "usb_storage"
          "uas"
          "sd_mod"
          "sr_mod"
        ];

        # Required to open the EFI partition and Yubikey
        kernelModules = [
          "vfat"
          "nls_cp437"
          "nls_iso8859-1"
          "usbhid"
        ];
      };

      loader = {
        grub = {
          enable = lib.mkForce true;
          device = lib.mkForce "nodev";
        };
        generic-extlinux-compatible.enable = lib.mkForce false;
        systemd-boot.enable = lib.mkForce false;
        efi.canTouchEfiVariables = lib.mkForce false;
        timeout = lib.mkForce 1;
      };

      initrd.luks.cryptoModules = let
          defaultModules = options.boot.initrd.luks.cryptoModules.default;
          deprecated = lib.optionals (lib.versionAtLeast config.boot.kernelPackages.kernel.version "7.0") [
            "aes_generic"
          ];
        in
          lib.subtractLists deprecated defaultModules;
    };

    networking = {
      hostName = "wyvern";
    };

    # Enable systemd-resolved for DNS resolution
    services.resolved = {
      enable = true;
      settings.Resolve = {
        Domains     = [ "~." ];
        NDDSEC      = "allow-downgrade";
        DNSOverTLS  = "opportunistic";
        LLMR        = "false";
        FallbackDNS = [
          "1.1.1.3"
          "1.0.0.3"
        ];
      };
    };

    # open firewall for mDNS
    networking.firewall.allowedUDPPorts = [ 5353 ];

    services.getty.autologinUser = lib.mkForce "root";

    services.openssh = {
      enable    = lib.mkForce true;
      allowSFTP = lib.mkForce false;
      settings  = {
        PasswordAuthentication          = lib.mkForce false;
        UsePAM                          = lib.mkForce false;
        KbdInteractiveAuthentication    = lib.mkForce false;
        challengeResponseAuthentication = lib.mkForce false;
        X11Forwarding                   = lib.mkForce false;
        PermitRootLogin                 = lib.mkForce "yes";
      };
      extraConfig = ''
        AllowTcpForwarding no
        AllowAgentForwarding no
        StreamLocalBindUnlink yes
        AllowStreamLocalForwarding no
        AuthenticationMethods publickey
        HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
        HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
        TrustedUserCAKeys /etc/ssh/user_ca.pub
      '';
    };

    # unlock user root
    users.users.root.hashedPassword = "*";

    systemd = {
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };

    security.pki.certificates = [
      ''
        OpikCA
        ======
        -----BEGIN CERTIFICATE-----
        MIICATCCAaigAwIBAgIUUgc8uKcAP+E/V4Ar14PYy1yd56owCgYIKoZIzj0EAwIw
        XzELMAkGA1UEBhMCSUQxETAPBgNVBAgTCFN1cmFiYXlhMRIwEAYDVQQHEwlFYXN0
        IEphdmExEjAQBgNVBAoTCU9waWsgSW5jLjEVMBMGA1UEAxMMT3BpayBJbmMuIENB
        MB4XDTI1MDMwOTEwMjUwMFoXDTMwMDMwODEwMjUwMFowXzELMAkGA1UEBhMCSUQx
        ETAPBgNVBAgTCFN1cmFiYXlhMRIwEAYDVQQHEwlFYXN0IEphdmExEjAQBgNVBAoT
        CU9waWsgSW5jLjEVMBMGA1UEAxMMT3BpayBJbmMuIENBMFkwEwYHKoZIzj0CAQYI
        KoZIzj0DAQcDQgAE54hCxJJcIqfjWNnBS16GTemx2w7d43G02NZtGVlNgSkyHoq3
        t7989LreKvW4v+7W1pb4IAIysIrDQcAb+MT9+qNCMEAwDgYDVR0PAQH/BAQDAgEG
        MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFBp31d4NJFL0aKYln8Wm6s6EBVJF
        MAoGCCqGSM49BAMCA0cAMEQCIFRcE0VRLWD/ZgeE5nEUM+UOCGkSkxP4ugQ4E9w+
        JiERAiAnVnYgmvoAXooraZINBd1Rs8/kx4eXFdk4XsEkV+JoLQ==
        -----END CERTIFICATE-----
      ''
    ];

    environment.defaultPackages = lib.mkForce [];

    environment.etc = let
       keyPath = builtins.getEnv "SSH_HOST_KEY_PATH";
    in {
      "ssh/ssh_host_ed25519_key" = {
        source = if keyPath != "" then /. + "${keyPath}/ssh_host_ed25519_key" else throw "SSH_HOST_KEY_PATH is not set!";
        mode = "0600";
      };

      "ssh/ssh_host_ed25519_key-cert.pub" = {
        source = if keyPath != "" then /. + "${keyPath}/ssh_host_ed25519_key-cert.pub" else throw "SSH_HOST_KEY_PATH is not set!";
        mode = "0644";
      };

      "ssh/ssh_host_rsa_key" = {
        source = if keyPath != "" then /. + "${keyPath}/ssh_host_rsa_key" else throw "SSH_HOST_KEY_PATH is not set!";
        mode = "0600";
      };

      "ssh/ssh_host_rsa_key-cert.pub" = {
        source = if keyPath != "" then /. + "${keyPath}/ssh_host_rsa_key-cert.pub" else throw "SSH_HOST_KEY_PATH is not set!";
        mode = "0644";
      };

      "ssh/user_ca.pub".text = ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMYc3UbzHDuwd3+8p1jsaIvcD0I61nEEsKDeYCDDm2fh User SSH Certificate Authority for Opik Network'';

      "ssl/certs/ca-cert.pem".text = ''
        -----BEGIN CERTIFICATE-----
        MIICATCCAaigAwIBAgIUUgc8uKcAP+E/V4Ar14PYy1yd56owCgYIKoZIzj0EAwIw
        XzELMAkGA1UEBhMCSUQxETAPBgNVBAgTCFN1cmFiYXlhMRIwEAYDVQQHEwlFYXN0
        IEphdmExEjAQBgNVBAoTCU9waWsgSW5jLjEVMBMGA1UEAxMMT3BpayBJbmMuIENB
        MB4XDTI1MDMwOTEwMjUwMFoXDTMwMDMwODEwMjUwMFowXzELMAkGA1UEBhMCSUQx
        ETAPBgNVBAgTCFN1cmFiYXlhMRIwEAYDVQQHEwlFYXN0IEphdmExEjAQBgNVBAoT
        CU9waWsgSW5jLjEVMBMGA1UEAxMMT3BpayBJbmMuIENBMFkwEwYHKoZIzj0CAQYI
        KoZIzj0DAQcDQgAE54hCxJJcIqfjWNnBS16GTemx2w7d43G02NZtGVlNgSkyHoq3
        t7989LreKvW4v+7W1pb4IAIysIrDQcAb+MT9+qNCMEAwDgYDVR0PAQH/BAQDAgEG
        MA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFBp31d4NJFL0aKYln8Wm6s6EBVJF
        MAoGCCqGSM49BAMCA0cAMEQCIFRcE0VRLWD/ZgeE5nEUM+UOCGkSkxP4ugQ4E9w+
        JiERAiAnVnYgmvoAXooraZINBd1Rs8/kx4eXFdk4XsEkV+JoLQ==
        -----END CERTIFICATE-----
      '';
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

      key-vault-path  = pkgs.writeShellScriptBin "set-key-vault-path" ''

      set -euo pipefail

      export VAULT_DIR="${key-vault}"
      export VAULT_KEY="$VAULT_DIR/wyvern.key.age"
      '';

    in with pkgs; [
      key-vault
      pbkdf2-sha512
      rbtohex
      hextorb
      yk-luks-gen
      run-installer
      run-ssh-patcher
      install-nixos
      key-vault-path
      rage
      disko
      cryptsetup
      openssl
      parted
      yubikey-personalization
      git
      parted
      gptfdisk
      e2fsprogs
      dosfstools
      efibootmgr
      mc
    ];
  };
}
