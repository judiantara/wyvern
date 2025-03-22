
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# sanity check
: "${TARGET_MACHINE:?}"
: "${VAULT_DIR:?}"

GITHUB="github:judiantara"
FORMATTED="/tmp/disko-done"

echo "Preparing LUKS key..."
rage -d -i "$HOME/.ssh/id_ed25519" "$VAULT_DIR/luks.tar.age" | tar --no-same-owner -xvC /tmp

echo "Generate $TARGET_MACHINE configuration..."
nix --experimental-features "nix-command flakes" flake new --refresh --template "$GITHUB/wyrmling#$TARGET_MACHINE" "/tmp/$TARGET_MACHINE"

if [ ! -f $FORMATTED ]; then
  echo "Partitioning $TARGET_MACHINE disk..."
  disko --mode zap_create_mount --flake "/tmp/$TARGET_MACHINE#$TARGET_MACHINE"
  touch $FORMATTED
  echo
fi

mkdir -p /mnt/{boot,nix/persist,etc/{nixos,ssh},var/{lib,log},srv,home}

echo "Install $TARGET_MACHINE SSH identity keys..."
rage -d -i "$HOME/.ssh/id_ed25519" "$VAULT_DIR/$TARGET_MACHINE.tar.age" | tar --no-same-owner -xvC /mnt/nix/persist
chmod 400 /mnt/nix/persist/etc/ssh/*_key
chmod 444 /mnt/nix/persist/etc/ssh/*.pub
echo

echo "Download $TARGET_MACHINE flake..."
nix --experimental-features "nix-command flakes" flake new --refresh --template "$GITHUB/wyrmling#$TARGET_MACHINE" /mnt/etc/nixos

echo "Install NixOS into $TARGET_MACHINE..."
nixos-install --channel unstable --no-channel-copy --no-root-password --flake "/mnt/etc/nixos#$TARGET_MACHINE" --root /mnt --cores 0

echo "Please reboot and then login to $TARGET_MACHINE as default user and run \"my-update -d\""
