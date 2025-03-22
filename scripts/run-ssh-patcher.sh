#!/usr/bin/env bash

set -euo pipefail

if (( $EUID != 0 )); then
  echo "Please run as root"
  exit 1
fi

# sanity check
: ${TARGET_MACHINE:?}
: ${VAULT_DIR:?}
: ${VAULT_KEY:?}

rm -rf $HOME/.ssh
rage -d -i $VAULT_KEY $VAULT_DIR/installer.tar.age | tar --no-same-owner -xvC $HOME
rm -f /etc/ssh/ssh_host*
rage -d -i $HOME/.ssh/id_ed25519 $VAULT_DIR/$TARGET_MACHINE.tar.age | tar --no-same-owner -xvC /
systemctl restart sshd
echo "Done!"
