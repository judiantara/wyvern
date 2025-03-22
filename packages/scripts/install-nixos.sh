
set -euo pipefail

function usage {
cat >&2 <<EOF
Usage: install-nixos [OPTIONS]

Install NixOS on (virtual) machine

Options:
  -m, --machine=machine  Name of target machine, required
  -h, --help             Show this help
EOF
}

if [ "$EUID" -ne 0 ]; then
  echo "Please run $0 as root"
  exit 1
fi

export LUKS_YUBIKEY='N'

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
      echo -e "Unhandled option '$1'"
      exit 2
    ;;
  esac
done

# shellcheck source=/dev/null
source "$(which set-key-vault-path)"

# sanity check
: "${TARGET_MACHINE:?}"
: "${VAULT_DIR:?}"
: "${VAULT_KEY:?}"

run-ssh-patcher

echo
echo "Install NixOS..."
echo "  - For host ${TARGET_MACHINE:?} with SSH host key from ${VAULT_DIR:?}/$TARGET_MACHINE.tar.age"
echo

# Start installation
run-installer
