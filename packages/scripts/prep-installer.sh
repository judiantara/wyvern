
set -euo pipefail

function usage {
cat >&2 <<EOF
Usage: prep-installer [OPTIONS]

Restore SSH keys from encrypted storage

Options:
  -m, --machine=name Name of host, required
  -h, --help         Show this help
EOF
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run $0 as root"
  exit 1
fi

WYVERN_DIR=$(readlink -f "$0" | xargs dirname)
export VAULT_DIR=$WYVERN_DIR/vault
export VAULT_KEY=$VAULT_DIR/wyvern.key.age

# Get CLI options
opts=$(getopt --options "m:h" --long "machine:,help" -- "$@")

# Inspect CLI options
eval set -- "$opts"
while true; do
  case $1 in
    -m|--machine)
      export TARGET_MACHINE=$2
      shift 2
    ;;
    -h|--help)
      usage
      exit 0
    ;;
    --)
      shift
      break
    ;;
    *)
      echo -e "Unknown option '$1'"
      exit 2
    ;;
  esac
done

# Sanity check
echo "Installing SSH host keys for: ${TARGET_MACHINE:?} from ${VAULT_DIR:?}/$TARGET_MACHINE.tar.age, decrypted using yubikey (please long press when asked for passphrase)"
echo

nix --experimental-features "nix-command flakes" develop "$WYVERN_DIR#run-ssh-patcher"
