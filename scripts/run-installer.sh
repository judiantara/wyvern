#!/usr/bin/env bash

set -euo pipefail

if (( $EUID != 0 )); then
  echo "Please run as root"
  exit 1
fi

# sanity check
: ${TARGET_MACHINE:?}
: ${FLAKE_ROOT:?}
: ${VAULT_DIR:?}

FLAKE_REPO=$FLAKE_ROOT#$TARGET_MACHINE

SALT="/tmp/salt.conf"
KEY="/tmp/luks.key"

if [ ! -f $SALT ]; then
  echo "Generate $TARGET_MACHINE luks key..."
  yk-luks-gen -c $SALT -f $KEY
  echo

  echo "Partitioning $TARGET_MACHINE disk..."
  disko --mode zap_create_mount --flake $FLAKE_REPO
  echo
fi

echo "Install $TARGET_MACHINE SSH identity keys..."
mkdir -p /mnt/{boot,nix/persist,etc/{nixos,ssh},var/{lib,log},srv}
rage -d -i $HOME/.ssh/id_ed25519 $VAULT_DIR/$TARGET_MACHINE.tar.age | tar --no-same-owner -xvC /mnt/nix/persist
echo

if [ -f $SALT ]; then
  echo "Install $TARGET_MACHINE luks salt..."
  cp /tmp/salt.conf /mnt/boot/
  echo
fi

echo "Install NixOS into $TARGET_MACHINE..."
nixos-install --channel unstable --no-channel-copy --no-root-password --no-write-lock-file --flake $FLAKE_REPO --root /mnt --cores 0
