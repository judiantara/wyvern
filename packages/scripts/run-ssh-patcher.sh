
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# sanity check
: "${TARGET_MACHINE:?}"
: "${VAULT_DIR:?}"
: "${VAULT_KEY:?}"

INSTALLER_SSH_KEY="$VAULT_DIR/installer.tar.age"

# replace root SSH keys with installer SSH keys, then use it as identity key for extracting target machine SSH keys
echo "Installing SSH keys for root from ${INSTALLER_SSH_KEY}, decrypted using yubikey (please long press when asked for passphrase)"
echo
rm -rf "$HOME/.ssh"
rage -d -i "$VAULT_KEY" "$INSTALLER_SSH_KEY" | tar --no-same-owner -xvC "$HOME"
echo

# replace livecd host SSH keys with target machine SSH keys
echo "Installing SSH host keys for: ${TARGET_MACHINE} from ${VAULT_DIR}/$TARGET_MACHINE.tar.age, decrypted using $HOME/.ssh/id_ed25519"
echo
rm -f /etc/ssh/ssh_host*
rage -d -i "$HOME/.ssh/id_ed25519" "$VAULT_DIR/$TARGET_MACHINE.tar.age" | tar --no-same-owner -xvC /
systemctl restart sshd
echo "Done!"
