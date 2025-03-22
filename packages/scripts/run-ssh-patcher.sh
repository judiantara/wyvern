
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# sanity check
: "${VAULT_DIR:?}"
: "${VAULT_KEY:?}"

INSTALLER_SSH_KEY="$VAULT_DIR/installer.tar.age"

# replace root SSH keys with installer SSH keys, then use it as identity key for extracting target machine SSH keys
echo "Installing SSH keys for root from $INSTALLER_SSH_KEY, decrypted using yubikey (please long press when asked for passphrase)"
echo
rm -rf "$HOME/.ssh"
rage -d -i "$VAULT_KEY" "$INSTALLER_SSH_KEY" | tar --no-same-owner -xvC "$HOME"
echo

# WYVERN_SSH_KEY="$VAULT_DIR/wyvern.tar.age"
# AGE_KEY="$HOME/.ssh/id_ed25519"
# echo "Installing SSH host keys from $WYVERN_SSH_KEY, decrypted using $AGE_KEY"
# echo
# rm -f /etc/ssh/ssh_host*
# rage -d -i "$AGE_KEY" "$WYVERN_SSH_KEY" | tar --no-same-owner -xvC /
# find /etc/ssh -type f -name "*.pub" -exec chmod 444 {} \;
# find /etc/ssh -type f -name "*_key" -exec chmod 400 {} \;
# systemctl restart sshd
# echo "Done!"
