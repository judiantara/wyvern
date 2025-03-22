
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# sanity check
: "${TARGET_MACHINE:?}"
: "${VAULT_DIR:?}"

INSTALLER_KEY="$HOME/.ssh/id_ed25519"
GITHUB="github:judiantara"
FORMATTED="/run/disko-done"
FLAKE=(nix --extra-experimental-features "flakes nix-command" flake)

echo "Preparing LUKS key..."
rage -d -i "$INSTALLER_KEY" "$VAULT_DIR/luks.tar.age" | tar --no-same-owner -xvC /run

echo "Pulling $TARGET_MACHINE configuration..."
"${FLAKE[@]}" new --refresh --template "$GITHUB/wyrmling#$TARGET_MACHINE" "/run/$TARGET_MACHINE"
"${FLAKE[@]}" update --flake "/run/$TARGET_MACHINE/"

if [ ! -f $FORMATTED ]; then
  echo "Partitioning $TARGET_MACHINE disk..."
  disko --mode zap_create_mount --flake "/run/$TARGET_MACHINE#$TARGET_MACHINE"
  touch $FORMATTED
  echo
fi

rm -rf "/run/$TARGET_MACHINE"

mkdir -p /mnt/{boot,nix/persist,etc/{nixos,ssh},var/{lib,log},srv,home}

echo "Install $TARGET_MACHINE SSH identity keys..."
rage -d -i "$INSTALLER_KEY" "$VAULT_DIR/$TARGET_MACHINE.tar.age" | tar --no-same-owner -xvC /mnt/nix/persist
chmod 400 /mnt/nix/persist/etc/ssh/*_key
chmod 444 /mnt/nix/persist/etc/ssh/*.pub
echo

echo "Pulling $TARGET_MACHINE flake..."
"${FLAKE[@]}" new --refresh --template "$GITHUB/wyrmling#$TARGET_MACHINE" /mnt/etc/nixos
"${FLAKE[@]}" update --flake /mnt/etc/nixos/
sleep 5

echo "Install NixOS into $TARGET_MACHINE..."
"${FLAKE[@]}" update --flake /mnt/etc/nixos
nixos-install --no-channel-copy --no-root-password --flake "/mnt/etc/nixos#$TARGET_MACHINE" --root /mnt --cores 0

echo "Please reboot and then login to $TARGET_MACHINE as default user and run \"my-update -d\""
