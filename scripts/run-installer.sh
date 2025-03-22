#!/usr/bin/env bash

set -euo pipefail

if (( $EUID != 0 )); then
  echo "Please run as root"
  exit 1
fi

# sanity check
: ${TARGET_MACHINE:?}
: ${TARGET_USER:?}
: ${VAULT_DIR:?}

SALT="/tmp/salt.conf"
KEY="/tmp/luks.key"

mkdir -p /mnt/{boot,nix/persist,etc/{nixos,ssh},var/{lib,log},srv}

tera $TEMPLATE_DIR/host-flake.tpl --env-only -o /mnt/etc/nixos/flake.nix

$FLAKE=/mnt/etc/nixos#$TARGET_MACHINE

if [ ! -f $SALT ]; then
  echo "Generate $TARGET_MACHINE luks key..."
  yk-luks-gen -c $SALT -f $KEY
  echo

  echo "Partitioning $TARGET_MACHINE disk..."
  disko --mode zap_create_mount --flake $FLAKE
  echo
fi

echo "Install $TARGET_MACHINE SSH identity keys..."
rage -d -i $HOME/.ssh/id_ed25519 $VAULT_DIR/$TARGET_MACHINE.tar.age | tar --no-same-owner -xvC /mnt/nix/persist
echo

if [ -f $SALT ]; then
  echo "Install $TARGET_MACHINE luks salt..."
  cp /tmp/salt.conf /mnt/boot/
  echo
fi

echo "Install NixOS into $TARGET_MACHINE..."
nixos-install --channel unstable --no-channel-copy --no-root-password --flake $FLAKE --root /mnt --cores 0

mkdir -p /mnt/home/$TARGET_USER/.config/home-manager

tera $TEMPLATE_DIR/user-flake.tpl --env-only -o /mnt/home/$TARGET_USER/.config/home-manager/flake.nix

chown -R 1000:1000 /mnt/home/$TARGET_USER/.config/home-manager

echo 'Please login to $TARGET_MACHINE as $TARGET_USER and run "home-manager switch"'
