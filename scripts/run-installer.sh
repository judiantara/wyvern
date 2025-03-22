#!/usr/bin/env bash

set -euo pipefail

if (( $EUID != 0 )); then
  echo "Please run as root"
  exit 1
fi

# sanity check
: ${TARGET_MACHINE:?}
: ${TARGET_USER:?}
: ${LUKS_YUBIKEY:?}
: ${VAULT_DIR:?}

SALT="/tmp/salt.conf"
KEY="/tmp/luks.key"
FORMATTED="/tmp/disko-done"

if [ "$LUKS_YUBIKEY" == "N" ]; then
  touch $KEY
  touch $SALT
fi

if [ ! -f $KEY ] || [ ! -f $SALT ]; then
  echo "Generate $TARGET_MACHINE luks key..."
  yk-luks-gen -c $SALT -f $KEY
  echo
fi

echo "Generate $TARGET_MACHINE configuration..."
mkdir -p /tmp/$TARGET_MACHINE
tera --template $TEMPLATE_DIR/host-flake.tpl --out /tmp/$TARGET_MACHINE/flake.nix --env-only

if [ ! -f $FORMATTED ]; then
  echo "Partitioning $TARGET_MACHINE disk..."
  disko --mode zap_create_mount --flake /tmp/$TARGET_MACHINE#$TARGET_MACHINE
  touch $FORMATTED
  echo
fi

mkdir -p /mnt/{boot,nix/persist,etc/{nixos,ssh},var/{lib,log},srv}

mv -vf /tmp/$TARGET_MACHINE/* /mnt/etc/nixos/

echo "Install $TARGET_MACHINE SSH identity keys..."
rage -d -i $HOME/.ssh/id_ed25519 $VAULT_DIR/$TARGET_MACHINE.tar.age | tar --no-same-owner -xvC /mnt/nix/persist
echo

if [ "$LUKS_YUBIKEY" == "Y" ] && [ -f $KEY ] && [ -f $SALT ]; then
  echo "Install $TARGET_MACHINE luks salt..."
  cp -f /tmp/salt.conf /mnt/boot/
  echo
fi

echo "Install NixOS into $TARGET_MACHINE..."
nixos-install --channel unstable --no-channel-copy --no-root-password --flake /mnt/etc/nixos#$TARGET_MACHINE --root /mnt --cores 0

mkdir -p /mnt/home/$TARGET_USER/.config/home-manager

tera --template $TEMPLATE_DIR/user-flake.tpl --out /mnt/home/$TARGET_USER/.config/home-manager/flake.nix  --env-only

chown -R 1000:1000 /mnt/home/$TARGET_USER

echo "Please login to $TARGET_MACHINE as $TARGET_USER and run \"home-manager build switch\""
