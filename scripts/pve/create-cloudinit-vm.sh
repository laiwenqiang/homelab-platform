#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/vm-cloudinit-config.sh
source "$SCRIPT_DIR/../lib/vm-cloudinit-config.sh"

APPLY=0
CONFIG=""

usage() {
  cat <<'EOF'
Usage: create-cloudinit-vm.sh --config <config.yaml> [--apply]

Creates one Proxmox VM from a Cloud-Init template described by YAML.
Default mode is dry-run: commands are printed but not executed.

Required YAML shape:
  vm:
    template_vmid: 9000
    vmid: 1050
    name: vm-example-01
    storage: local-lvm        # optional clone target storage
    cores: 2
    memory_mb: 2048
    disk: 30G                 # optional resize target
    network:
      bridge: vmbr0
      ip: 192.168.5.250/24
      gateway: 192.168.5.1
    cloudinit:
      user: debian
      ssh_public_key_file: inventory/vms/examples/example.pub
    start: false
EOF
}

info() {
  echo "[info] $*"
}

quote_cmd() {
  printf '%q' "$1"
}

print_command() {
  local first=1 arg
  for arg in "$@"; do
    if [[ "$first" -eq 1 ]]; then
      first=0
    else
      printf ' '
    fi
    quote_cmd "$arg"
  done
  printf '\n'
}

run_command() {
  print_command "$@"
  if [[ "$APPLY" -eq 1 ]]; then
    "$@"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)
        [[ $# -ge 2 ]] || vmcfg_fail "--config requires a path"
        CONFIG="$2"
        shift 2
        ;;
      --apply)
        APPLY=1
        shift
        ;;
      --dry-run)
        APPLY=0
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        vmcfg_fail "unknown argument: $1"
        ;;
    esac
  done

  [[ -n "$CONFIG" ]] || vmcfg_fail "--config is required"
}

validate_apply_environment() {
  if [[ "$APPLY" -eq 0 ]]; then
    info "dry-run mode; add --apply to execute these commands"
    return
  fi

  vmcfg_require_cmd qm
  if qm status "$VMID" >/dev/null 2>&1; then
    vmcfg_fail "VMID already exists: $VMID"
  fi
}

build_and_run() {
  local clone_cmd=(qm clone "$TEMPLATE_VMID" "$VMID" --name "$NAME" --full 1)
  if [[ -n "$STORAGE" ]]; then
    clone_cmd+=(--storage "$STORAGE")
  fi

  run_command "${clone_cmd[@]}"
  run_command qm set "$VMID" --cores "$CORES" --memory "$MEMORY_MB"
  run_command qm set "$VMID" --net0 "virtio,bridge=$BRIDGE"
  run_command qm set "$VMID" --ciuser "$CI_USER" --sshkeys "$SSH_PUBLIC_KEY_FILE_EXPANDED"
  run_command qm set "$VMID" --ipconfig0 "ip=$IP,gw=$GATEWAY"

  if [[ -n "$DISK" ]]; then
    run_command qm resize "$VMID" scsi0 "$DISK"
  fi

  run_command qm cloudinit update "$VMID"

  if [[ "$START" == "true" ]]; then
    run_command qm start "$VMID"
  fi
}

main() {
  parse_args "$@"
  vmcfg_load "$CONFIG"
  validate_apply_environment
  build_and_run

  if [[ "$APPLY" -eq 1 ]]; then
    info "VM creation commands completed for $NAME ($VMID)"
    info "Next checks: qm config $VMID; qm status $VMID; SSH to $CI_USER@${IP%%/*} after Cloud-Init finishes"
  else
    info "dry-run complete; no VM was created"
  fi
}

main "$@"
