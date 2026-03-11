#!/bin/bash
#
# e1000e NIC guard - hardening + watchdog (combined)
#
# 1. Startup: disable EEE and NIC offloading to prevent Hardware Unit Hang
# 2. Monitor: ping gateway every 30s, auto-recover on consecutive failures
#
# Known issue: Intel I219 series NIC with e1000e driver triggers
# "Detected Hardware Unit Hang" due to EEE race condition and
# TX-path offloading quirks. Disabling both is the community-proven fix.
#
# References:
#   https://forum.proxmox.com/threads/106001/
#   https://www.garrettlaman.com/Homelab/Fixing-Intel-e1000e-NIC-hangs-on-Proxmox-nodes
#

set -euo pipefail

NIC="${1:-enp0s31f6}"
PING_IFACE="${2:-$NIC}"
GATEWAY="${3:-192.168.5.1}"
CHECK_INTERVAL=30
FAIL_THRESHOLD=3
LOG_TAG="e1000e-guard"

fail_count=0

log() { logger -t "$LOG_TAG" "$1"; }

# --- Phase 1: Apply NIC hardening ---
apply_hardening() {
    local nic="$1"

    # Disable EEE
    if ethtool --set-eee "$nic" eee off 2>/dev/null; then
        log "EEE disabled on $nic"
    else
        log "WARNING: Failed to disable EEE on $nic (may not be supported)"
    fi

    # Disable NIC offloading (TSO/GSO/GRO)
    if ethtool -K "$nic" tso off gso off gro off 2>/dev/null; then
        log "TSO/GSO/GRO offloading disabled on $nic"
    else
        log "WARNING: Failed to disable some offloading features on $nic"
    fi
}

# --- Phase 2: Watchdog loop ---
watchdog() {
    local nic="$1"
    local ping_iface="$2"
    local gateway="$3"

    while true; do
        if ! ping -c 1 -W 2 -I "$ping_iface" "$gateway" &>/dev/null; then
            fail_count=$((fail_count + 1))
            log "WARNING: $nic ping via $ping_iface to $gateway failed ($fail_count/$FAIL_THRESHOLD)"

            if [ "$fail_count" -ge "$FAIL_THRESHOLD" ]; then
                log "CRITICAL: $nic appears hung, initiating reset"
                ip link set "$nic" down
                sleep 2
                ip link set "$nic" up
                sleep 3
                apply_hardening "$nic"
                fail_count=0
                log "Reset complete: $nic is back up, hardening re-applied"
            fi
        else
            fail_count=0
        fi
        sleep "$CHECK_INTERVAL"
    done
}

# --- Main ---
log "Starting e1000e-guard for $NIC (ping iface: $PING_IFACE, gateway: $GATEWAY, interval: ${CHECK_INTERVAL}s, threshold: $FAIL_THRESHOLD)"
apply_hardening "$NIC"
log "Initial hardening applied, entering watchdog mode"
watchdog "$NIC" "$PING_IFACE" "$GATEWAY"
