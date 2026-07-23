# Current Work Plan

## Grafana + Prometheus MVP

- [x] Add `services/monitoring` Compose stack for Grafana and Prometheus.
- [x] Add Prometheus self-scrape configuration and bounded retention.
- [x] Add Grafana datasource provisioning and reserved dashboard provisioning structure.
- [x] Document deployment, verification, backup, and rollback steps.
- [x] Keep inventory/docs consistent with `grafana.tools.home` and `lxc-monitor-01`.
- [ ] Run repository validation checks.

## Review

- Added `services/monitoring` with Prometheus + Grafana Compose configuration.
- Added Prometheus self-scrape and 15-day retention.
- Added Grafana Prometheus datasource provisioning and reserved dashboard provisioning structure.
- Documented deployment, verification, backup, rollback, and out-of-scope items.
- Updated `docs/01-architecture.md` so Grafana and the observability center align with the tools network.
- Validation run:
  - `python3` YAML structure/contract check for monitoring Compose/provisioning files: passed.
  - `bash scripts/validate/check-no-secrets.sh`: passed.
  - `python3 ./.trellis/scripts/task.py validate .trellis/tasks/05-26-grafana-monitoring`: passed.
  - `pnpm lint`, `pnpm type-check`, `pnpm test`: not applicable because this repository has no `package.json`.
  - `docker compose config`: not run because Docker is not installed in this environment.

## PVE Deployment Plan for Prometheus + Grafana

- [x] Confirm `lxc-monitor-01` does not already exist on pve-01.
- [x] Confirm CTID `1022` and IP `192.168.5.22` are unused.
- [x] Confirm PVE local backup artifacts exist before further infrastructure changes.
- [x] Create `lxc-monitor-01` as CTID `1022` with 2 vCPU / 2GB RAM / 30GB disk on `local-zfs`.
- [x] Enable Docker-compatible LXC features (`nesting=1`, `keyctl=1`).
- [x] Install Docker and Docker Compose plugin in the LXC.
- [x] Deploy `services/monitoring` from `feature/prometheus-monitoring-only`.
- [x] Run `docker compose config`, `up -d`, logs, Prometheus self-scrape, Grafana datasource checks.
- [x] Verify reboot recovery.
- [x] Confirm backup coverage for CT `1022` and monitoring Docker volumes.
- [ ] Configure and verify `grafana.tools.home` DNS/reverse proxy entry.
- [ ] Decide trusted Docker image source/mirror/cache for repeatable deployments.

## PVE Deployment Review

- Created `lxc-monitor-01` on pve-01 as CTID `1022`, IP `192.168.5.22`, 2 vCPU, 2GB RAM, 30GB `local-zfs`, `onboot=1`, `nesting=1,keyctl=1`.
- Installed Docker Engine and Docker Compose plugin in the LXC.
- Deployed the monitoring stack from `feature/prometheus-monitoring-only` under `/opt/homelab-platform/services/monitoring`.
- Docker Hub access from pve-01/LXC timed out; Prometheus was loaded via Quay retag and Grafana was imported manually as a local image. This needs a trusted mirror/cache or image mirroring policy before repeatable production redeploys.
- Runtime checks passed: Compose stack up, Prometheus config valid, Prometheus self-scrape `up=1`, Grafana `/api/health` OK, Grafana Prometheus datasource provisioned as default.
- Reboot recovery passed: after `pct reboot 1022`, Grafana health recovered and Prometheus self-scrape remained `up=1`.
- Domain gate is not satisfied yet: `http://grafana.tools.home/api/health` timed out during DNS resolution from pve-01, while direct `http://192.168.5.22:3000/api/health` is healthy.
- Backup gate passed for initial local coverage: `local:backup/vzdump-lxc-1022-2026_06_02-19_45_29.tar.zst` exists for CT `1022`, and the backup includes the rootfs where monitoring Docker volumes live.

## HomeLab Basic Metrics Collection Plan

- [x] Add a Prometheus `node_exporter` scrape job that loads targets from a dedicated file_sd target file.
- [x] Register HomeLab inventory hosts with IP/role/zone labels for basic host metrics collection on port `9100`.
- [x] Document node_exporter installation requirements for PVE, Debian LXC/VM, and optional OpenWrt-style hosts.
- [x] Document validation commands for Prometheus target health and common `down` causes.
- [x] Run monitoring config validation and repository secret check after changes.

## HomeLab Basic Metrics Collection Review

- Added `services/monitoring/prometheus/targets/node-exporter.yml` with HomeLab host targets from inventory on `9100/tcp` and labels for `instance`, `zone`, `role`, and `type`.
- Updated Prometheus to load node_exporter targets through `file_sd_configs` and updated Compose to mount `prometheus/targets` read-only.
- Updated monitoring README and deployment runbook with exporter install requirements, target health validation, and expected `down` causes.
- Validation passed: Python YAML structure check, `bash scripts/validate/check-no-secrets.sh`, direct `scripts/validate/check-no-secrets.sh`, `bash -n scripts/validate/check-no-secrets.sh`, `git diff --check`, and Trellis task validation.
- `docker compose config` was not run locally because Docker is not installed in this environment.

## Grafana Dashboard Comparison Plan

- [x] Enhance `homelab-node-overview.json` into a compact HomeLab-focused dashboard with better overview, variables, rows, host info, CPU, memory, filesystem, and network panels.
- [x] Add a second provisioned dashboard based on the shared Grafana `Node Exporter Full` dashboard ID `1860` for direct side-by-side evaluation.
- [x] Validate both dashboard JSON files and run repository checks available in this environment.
- [x] Deploy both dashboards to `lxc-monitor-01` and verify Grafana provisioning/runtime health.
- [ ] Leave final dashboard choice for browser comparison after deployment.

## Grafana Dashboard Comparison Review

- Deployed `grafana/dashboards/homelab-node-overview.json` and `grafana/dashboards/node-exporter-full-1860.json` to CT `1022` under `/opt/homelab-platform/services/monitoring`.
- Restarted `monitoring-grafana`; `/api/health` returned database `ok`, Grafana version `11.4.0`.
- Grafana dashboard provisioning logs completed with no `provisioning.dashboard` errors.
- Prometheus validation queries returned data: `sum(up{job="node_exporter"})=4`, `node_uname_info` exists for `pve-01`, `lxc-monitor-01`, `vm-openclaw-01`, and `vm-openwrt-01`; CPU, memory, and filesystem overview queries returned values.
- Next manual check: compare `HomeLab Node Overview` and `Node Exporter Full 1860` in Grafana UI before choosing the final default dashboard.

## Grafana 1860 Dashboard Cleanup Plan

- [x] Remove `grafana/dashboards/homelab-node-overview.json` so Grafana only provisions the 1860 dashboard.
- [x] Update `services/monitoring/README.md` to document only `node-exporter-full-1860.json`.
- [x] Fix the 1860 `node` / Instance variable so it is chained to selected `nodename` and no longer keeps an `All` option after selecting a specific node name.
- [x] Validate dashboard JSON, variable contract, whitespace, secrets, and Trellis task state.
- [x] Deploy to CT `1022`, remove the old compact dashboard file remotely, restart Grafana, and verify provisioning plus Prometheus variable queries.

## Grafana 1860 Dashboard Cleanup Review

- Local cleanup removed `grafana/dashboards/homelab-node-overview.json`; README now documents only `node-exporter-full-1860.json`.
- Updated the 1860 `node` / Instance variable: `includeAll=false`, removed `allValue`, cleared saved current value, and kept query `label_values(node_uname_info{job="$job", nodename=~"$nodename"}, instance)`.
- Validation passed: `python3 -m json.tool`, dashboard variable contract check, `git diff --check`, `bash scripts/validate/check-no-secrets.sh`, and Trellis task validation.
- Deployed cleanup to CT `1022`; remote `grafana/dashboards` now contains only `node-exporter-full-1860.json`.
- Restarted Grafana; `/api/health` returned database `ok`, dashboard provisioning completed with no `provisioning.dashboard` errors, and Prometheus `node_uname_info` queries returned nodename/instance data.
- Follow-up fix deployed: removed the `All` option from the 1860 `nodename` / Node Name variable as well as the `node` / Instance variable; remote JSON contract verification passed and Grafana provisioning completed again.

## Windows Lab VM Inventory Plan

- [x] Add an optional `vm-windows-dev-01` entry for the Windows Codex bridge in `inventory/hosts.md`.
- [x] Reserve a lab-zone IP for `vm-windows-dev-01` in `inventory/ips.md`.
- [x] Keep the VM marked optional / on-demand because current 32GB RAM capacity is tight.
- [x] Document the intended resource shape as a Windows 11 Pro bridge VM, not LXC, with enough CPU/RAM/disk for the Codex App bridge role.
- [x] Validate inventory consistency and review local diff.

## Windows Lab VM Inventory Review

- Added optional `vm-windows-dev-01` in `inventory/hosts.md` as a lab VM at `192.168.5.51`, with 4 vCPU, 8GB RAM, and 120GB disk for the Windows 11 Pro Codex bridge role.
- Updated optional resource totals to RAM `38.5GB` and disk `~550GB`, keeping the note that this VM should default to powered off and may require RAM upgrade if used long term.
- Added a lab-zone table to `inventory/ips.md` with `vm-k8s-01` at `192.168.5.50` and the Windows Codex bridge at `192.168.5.51`; renumbered following sections.
- Validation passed: `git diff --check`, Python inventory consistency check, and Trellis task validation.

## Windows Lab VM Implementation Plan

### Target

- Name: `vm-windows-dev-01`
- OS edition: Windows 11 Pro
- Purpose: Windows Codex App bridge from iPhone ChatGPT to the existing Linux Codex execution host
- Zone/IP: `lab` / `192.168.5.51`
- PVE model: OVMF/UEFI, q35, EFI disk, TPM 2.0, VirtIO SCSI disk, VirtIO network, QEMU Guest Agent enabled
- Initial resources: 4 vCPU / 8GB RAM / 120GB disk, with room to reduce later if bridge-only usage is light
- Runtime posture: optional, powered off by default, start only when needed

### Actual workflow

1. User enters a request in iPhone ChatGPT.
2. iPhone reaches the Windows Codex bridge in HomeLab.
3. Windows Codex App uses SSH to start Codex on a Linux execution host.
4. Linux reads code, runs Maven/tests, modifies the Git working tree, and produces diffs/logs.
5. Results return from Linux to Windows.
6. Windows syncs results back to iPhone.
7. User approves, adds requirements, or asks for changes from the phone.

### Architecture split

- Windows is a control-plane bridge: app session, phone connectivity, SSH orchestration, result relay.
- Linux is the execution/data plane: repository checkout, build tools, Maven, tests, file edits, Git state.
- Do not put source repos, Maven caches, build outputs, or long-running development containers on Windows unless explicitly needed later.

### Phase 0 — Preconditions

- [ ] Confirm PVE backups/snapshots are healthy before adding a Windows bridge VM.
- [ ] Confirm `192.168.5.51` and chosen VMID are unused on pve-01.
- [ ] Confirm available storage on `local-zfs` is enough for Windows disk plus snapshots/backups.
- [ ] Prepare a Windows 11 ISO and the VirtIO driver ISO on PVE storage.
- [ ] Treat the current Linux machine as the Codex execution host; confirm its hostname/IP before wiring Windows SSH access.
- [ ] Confirm the current Linux execution host already has repo access, Maven/toolchains, tests, and enough resources.
- [ ] Decide SSH identity flow from Windows bridge to current Linux host: dedicated key, passphrase/agent policy, allowed command/user scope, and no private keys in Git.

### Phase 1 — Create Windows bridge VM

- [ ] Use PVE manual ISO installation for the first build, operated from PVE by Claude with user approval.
- [ ] Create a PVE VM named `vm-windows-dev-01` for Windows 11 Pro with OVMF/UEFI, q35 machine type, EFI disk, TPM 2.0, VirtIO SCSI disk, VirtIO network, and QEMU Guest Agent enabled.
- [ ] Prefer UEFI Secure Boot / pre-enrolled keys if the installed PVE version supports it; do not bypass Windows 11 hardware checks unless explicitly approved later.
- [ ] Suggested VMID: verify an unused lab VMID on PVE before creation; do not assume it is free.
- [ ] Allocate initial resources: 4 vCPU, 8GB RAM, 120GB disk on `local-zfs`; because Windows is bridge-only, consider reducing disk before creation if PVE storage is tight.
- [ ] Mount both ISOs: Windows 11 installer ISO and VirtIO driver ISO.
- [ ] During Windows setup, choose Windows 11 Pro and load the VirtIO storage driver from the VirtIO ISO if the disk is not visible.
- [ ] After first boot, install VirtIO network/balloon/storage drivers and QEMU Guest Agent from the VirtIO ISO.
- [ ] Confirm QEMU Guest Agent is running and visible from PVE before treating the VM as ready.
- [ ] Set static IP `192.168.5.51/24`, gateway `192.168.5.1`, DNS per lab policy, and hostname `vm-windows-dev-01`.
- [ ] Install only the Windows-side Codex App and bridge dependencies needed to SSH into the Linux execution host; do not install repo/build toolchains on Windows for the first build.
- [ ] Create snapshot `pre-windows-codex-bridge` after Windows + drivers + app prerequisites are stable.

### Phase 2 — Existing Linux Codex execution host

- [ ] Use the current Linux machine as the Codex execution host; do not create another Linux VM for this flow.
- [ ] Keep repositories on Linux local storage, not on Windows or SMB mounts.
- [ ] Confirm Codex CLI/app runtime, Git, SSH, Maven, Java, Node/Python are installed as required by target repositories.
- [ ] Configure per-repo working directories and confirm the Linux user has least-privilege access.
- [ ] Configure Linux-side logs so command output, diffs, and test results can be sent back to Windows without exposing secrets.
- [ ] Create a Linux snapshot or backup point after the execution environment is validated if this host is managed by PVE.

### Phase 3 — Windows-to-Linux bridge setup

- [ ] Generate or install a dedicated Windows-to-Linux SSH key; restrict it to the Linux Codex user.
- [ ] Verify Windows can SSH to Linux and start a non-destructive Codex/Linux command.
- [ ] Configure the Windows Codex App to launch remote Linux Codex over SSH rather than using local Windows/WSL execution.
- [ ] Verify result relay: Linux command output, Maven/test logs, and Git diff return to Windows and then to iPhone.
- [ ] Keep Windows as stateless as possible; all project state should remain on Linux.

### Phase 4 — Network/security controls

- [ ] Allow iPhone/client access only to the Windows bridge ports required by the Codex App.
- [ ] Allow Windows bridge to reach only the Linux Codex execution host over SSH and required update/auth endpoints.
- [ ] Keep `lab -> mgmt` blocked, especially PVE `192.168.5.10:22/8006`.
- [ ] Limit RDP/interactive Windows access to trusted management/client hosts only.
- [ ] Prevent Linux execution host from exposing repo/workspace services broadly; SSH should remain the control path.

### Phase 5 — End-to-end validation

- [ ] From iPhone, submit a harmless request through ChatGPT to the Windows Codex bridge.
- [ ] Confirm Windows starts Linux Codex via SSH.
- [ ] Confirm Linux reads the repo, runs a safe command such as `git status`, and returns output.
- [ ] Confirm Linux can run Maven/tests for a representative repo and return logs.
- [ ] Confirm Linux can produce a diff and return it to Windows/iPhone without committing automatically.
- [ ] Confirm approval/change loop from iPhone works before allowing real repository edits.
- [ ] Verify no tokens, SSH keys, API responses, or secret values are written to Git or logs.

### Phase 6 — Backup and rollback

- [ ] Add Windows bridge VM to backup policy only after the app/SSH bridge is stable; bridge state should remain minimal.
- [ ] Prioritize Linux execution host backups for repos/toolchains because actual code/build state lives there.
- [ ] Rollback path: revert Windows to `pre-windows-codex-bridge`; revert Linux execution host to its validated snapshot if toolchain changes break Codex execution.
- [ ] Record restore test in `docs/05-runbooks/backup-restore-drill.md` when a backup is restored.

### Deferred / out of scope for first build

- Running code builds, Maven, tests, Docker Desktop, or repository state directly on Windows.
- WSL2 as the primary execution path; use it only if the SSH-to-Linux model proves insufficient.
- Automated Windows provisioning with Cloudbase-Init or unattend.
- Always-on Windows service exposure through reverse proxy.
- Windows metrics exporter integration; add later only if the bridge VM becomes long-lived.

## HomeLab Basic Metrics Deployment Review

- pve-01 currently has one LXC target: CT `1022` / `lxc-monitor-01`; VMs `1030` and `1081` cannot be managed through `pct exec`.
- Installed `prometheus-node-exporter` on pve-01 and CT `1022`, enabled the systemd service, and verified `/metrics` on `192.168.5.10:9100` and `192.168.5.22:9100` from pve-01.
- Deployed the updated monitoring config to `/opt/homelab-platform` inside CT `1022`, recreated/restarted Prometheus, and fixed `prometheus/targets` permissions to be readable by the Prometheus container.
- Runtime validation passed: Prometheus config check succeeded with no file_sd warning; `up{job="prometheus"}=1`; node_exporter targets for `pve-01` and `lxc-monitor-01` report `up=1`.
- Installed `prometheus-node-exporter` on `vm-openclaw-01` / `192.168.5.81`, enabled the systemd service, verified local `/metrics`, and confirmed Prometheus reports `up{job="node_exporter",instance="vm-openclaw-01"}=1`.
- Installed official static `node_exporter` v1.11.1 on `vm-openwrt-01` / `192.168.5.30` because OpenWrt 23.05.5 package feeds did not expose a Prometheus exporter package; installed `/usr/sbin/node_exporter` with a procd init script, enabled autostart, verified local `/metrics`, verified pve-01 reachability, and confirmed Prometheus reports `up{job="node_exporter",instance="vm-openwrt-01"}=1`.
- Documented the OpenWrt 23.05.x / x86_64 static node_exporter installation path in `services/monitoring/README.md` and `docs/05-runbooks/monitoring-deploy.md`.
- Remaining node_exporter targets are expected `down` until those machines exist and have exporters installed: `lxc-nginx-01`, `lxc-adguard-01`, `lxc-logging-01`, `lxc-trendradar-01`, `lxc-lobechat-01`, `vm-k8s-01`, and `vm-model-01`.
- Grafana visibility issue root cause: Prometheus had node_exporter data, but Grafana had no dashboard JSON beyond `.gitkeep`, so the UI had nothing to display by default.
- Added and deployed `grafana/dashboards/homelab-node-overview.json`; Grafana dashboard provisioning completed and Prometheus dashboard query samples returned data for `pve-01`, `lxc-monitor-01`, `vm-openclaw-01`, and `vm-openwrt-01`.
- Post-dashboard local validation passed: `python3 -m json.tool`, dashboard contract check, `git diff --check`, `bash scripts/validate/check-no-secrets.sh`, and Trellis task validation.
