#!/usr/bin/env bash

vmcfg_fail() {
  echo "[fail] $*" >&2
  exit 1
}

vmcfg_warn() {
  echo "[warn] $*" >&2
}

vmcfg_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || vmcfg_fail "missing required command: $1"
}

vmcfg_yq_read() {
  yq -r "$1 // \"\"" "$VMCFG_CONFIG"
}

vmcfg_is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

vmcfg_validate_hostname() {
  local value="$1"
  [[ "$value" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]
}

vmcfg_validate_cidr_ipv4() {
  local value="$1" ip
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]] || return 1
  ip="${value%/*}"
  vmcfg_validate_ipv4 "$ip"
}

vmcfg_validate_ipv4() {
  local value="$1" octet
  local -a octets
  [[ "$value" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  IFS='.' read -r -a octets <<< "$value"
  for octet in "${octets[@]}"; do
    (( 10#$octet <= 255 )) || return 1
  done
}

vmcfg_expand_path() {
  local path="$1"
  if [[ "$path" == ~/* ]]; then
    printf '%s/%s\n' "$HOME" "${path#~/}"
  else
    printf '%s\n' "$path"
  fi
}

vmcfg_check_inventory_conflict() {
  local field="$1"
  local value="$2"
  local expected_name="$3"
  local files=(inventory/hosts.md inventory/ips.md)
  local file line

  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      if [[ "$line" != *"$expected_name"* ]]; then
        vmcfg_warn "$field '$value' appears in $file but not on a line containing '$expected_name'"
        vmcfg_warn "  $line"
      fi
    done < <(grep -F "$value" "$file" || true)
  done
}

vmcfg_load() {
  VMCFG_CONFIG="$1"
  [[ -f "$VMCFG_CONFIG" ]] || vmcfg_fail "config file not found: $VMCFG_CONFIG"

  vmcfg_require_cmd yq
  vmcfg_require_cmd ssh-keygen
  yq '.' "$VMCFG_CONFIG" >/dev/null

  TEMPLATE_VMID="$(vmcfg_yq_read '.vm.template_vmid')"
  VMID="$(vmcfg_yq_read '.vm.vmid')"
  NAME="$(vmcfg_yq_read '.vm.name')"
  STORAGE="$(vmcfg_yq_read '.vm.storage')"
  CORES="$(vmcfg_yq_read '.vm.cores')"
  MEMORY_MB="$(vmcfg_yq_read '.vm.memory_mb')"
  DISK="$(vmcfg_yq_read '.vm.disk')"
  BRIDGE="$(vmcfg_yq_read '.vm.network.bridge')"
  IP="$(vmcfg_yq_read '.vm.network.ip')"
  GATEWAY="$(vmcfg_yq_read '.vm.network.gateway')"
  CI_USER="$(vmcfg_yq_read '.vm.cloudinit.user')"
  SSH_PUBLIC_KEY_FILE="$(vmcfg_yq_read '.vm.cloudinit.ssh_public_key_file')"
  START="$(vmcfg_yq_read '.vm.start')"
  [[ -n "$START" ]] || START="false"

  for pair in \
    "vm.template_vmid:$TEMPLATE_VMID" \
    "vm.vmid:$VMID" \
    "vm.name:$NAME" \
    "vm.cores:$CORES" \
    "vm.memory_mb:$MEMORY_MB" \
    "vm.network.bridge:$BRIDGE" \
    "vm.network.ip:$IP" \
    "vm.network.gateway:$GATEWAY" \
    "vm.cloudinit.user:$CI_USER" \
    "vm.cloudinit.ssh_public_key_file:$SSH_PUBLIC_KEY_FILE"; do
    local key="${pair%%:*}"
    local value="${pair#*:}"
    [[ -n "$value" ]] || vmcfg_fail "missing required field: $key"
  done

  vmcfg_is_uint "$TEMPLATE_VMID" || vmcfg_fail "vm.template_vmid must be numeric"
  vmcfg_is_uint "$VMID" || vmcfg_fail "vm.vmid must be numeric"
  [[ "$TEMPLATE_VMID" != "$VMID" ]] || vmcfg_fail "vm.vmid must differ from vm.template_vmid"
  vmcfg_is_uint "$CORES" || vmcfg_fail "vm.cores must be numeric"
  vmcfg_is_uint "$MEMORY_MB" || vmcfg_fail "vm.memory_mb must be numeric"
  vmcfg_validate_hostname "$NAME" || vmcfg_fail "vm.name must be hostname-like"
  vmcfg_validate_cidr_ipv4 "$IP" || vmcfg_fail "vm.network.ip must be IPv4 CIDR, e.g. 192.168.5.50/24"
  vmcfg_validate_ipv4 "$GATEWAY" || vmcfg_fail "vm.network.gateway must be IPv4, e.g. 192.168.5.1"
  vmcfg_validate_hostname "$CI_USER" || vmcfg_fail "vm.cloudinit.user must be username-like"

  if [[ -n "$DISK" && ! "$DISK" =~ ^[0-9]+[GM]$ ]]; then
    vmcfg_fail "vm.disk must look like 30G or 1024M"
  fi

  if [[ "$START" != "true" && "$START" != "false" ]]; then
    vmcfg_fail "vm.start must be true or false"
  fi

  SSH_PUBLIC_KEY_FILE_EXPANDED="$(vmcfg_expand_path "$SSH_PUBLIC_KEY_FILE")"
  [[ -f "$SSH_PUBLIC_KEY_FILE_EXPANDED" ]] || vmcfg_fail "SSH public key file not found: $SSH_PUBLIC_KEY_FILE"
  ssh-keygen -l -f "$SSH_PUBLIC_KEY_FILE_EXPANDED" >/dev/null || vmcfg_fail "invalid SSH public key: $SSH_PUBLIC_KEY_FILE"

  vmcfg_check_inventory_conflict "VM name" "$NAME" "$NAME"
  vmcfg_check_inventory_conflict "IP" "${IP%%/*}" "$NAME"
}
