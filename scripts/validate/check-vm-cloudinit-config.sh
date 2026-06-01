#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/vm-cloudinit-config.sh
source "$SCRIPT_DIR/../lib/vm-cloudinit-config.sh"

usage() {
  cat <<'EOF'
Usage: check-vm-cloudinit-config.sh <config.yaml>

Validates the YAML schema for one Proxmox Cloud-Init VM config.
Requires yq v4.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

[[ $# -eq 1 ]] || { usage >&2; exit 2; }

vmcfg_load "$1"
echo "[ok] VM Cloud-Init config is valid: $1"
