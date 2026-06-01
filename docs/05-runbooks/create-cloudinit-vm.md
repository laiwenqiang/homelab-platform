# Cloud-Init VM 创建 Runbook

## 目标

使用 `scripts/pve/create-cloudinit-vm.sh` 从既有 Proxmox Cloud-Init Template 创建单台 VM，并把 VM 参数保存在 YAML 配置中。

## 适用范围

- PVE host：`pve-01`
- 模板来源：Debian Cloud Image + Cloud-Init VM Template
- 创建方式：`qm clone` + `qm set` + `qm cloudinit update`
- 配置文件：YAML

第一版只支持创建单台 VM，不支持批量创建、Terraform、DNS/反代/防火墙自动配置或 guest 内二次初始化。

## 前置条件

在 PVE host 上确认：

```bash
command -v qm
command -v yq
command -v ssh-keygen
qm status <template-vmid>
```

要求：

- Cloud-Init template 已完成 `cloud-init clean` 和 machine-id 清理。
- Template 已转换为 PVE template。
- SSH public key 文件存在，只使用公钥登录。
- 目标 VMID 未被占用。
- 目标 IP 已在 `inventory/ips.md` / `inventory/hosts.md` 中规划或确认不冲突。

## 配置文件

从示例复制：

```bash
cp inventory/vms/examples/cloudinit-vm.example.yaml inventory/vms/vm-k8s-01.yaml
```

字段说明：

```yaml
vm:
  template_vmid: 9000        # PVE Cloud-Init template VMID
  vmid: 1050                 # 新 VMID
  name: vm-example-01        # 新 VM 名称
  storage: local-lvm         # 可选，clone 目标 storage
  cores: 2
  memory_mb: 2048
  disk: 30G                  # 可选，创建后 resize scsi0
  network:
    bridge: vmbr0
    ip: 192.168.5.250/24
    gateway: 192.168.5.1
  cloudinit:
    user: debian
    ssh_public_key_file: ~/.ssh/id_ed25519.pub
  start: false               # true 时创建后启动
```

示例配置使用 `inventory/vms/examples/example.pub` 作为非敏感示例公钥；真实 VM 配置应改成你的运维公钥路径。

## 校验配置

```bash
bash scripts/validate/check-vm-cloudinit-config.sh inventory/vms/vm-k8s-01.yaml
```

校验内容：

- YAML 可解析。
- 必填字段存在。
- VMID/CPU/RAM 是数字。
- VMID 与 template VMID 不相同。
- VM 名称符合 hostname 风格。
- IP 使用 CIDR 格式，gateway 使用 IPv4 格式。
- SSH public key 文件存在且可被 `ssh-keygen` 识别。
- 与 `inventory/hosts.md` / `inventory/ips.md` 中已有 name/IP 做冲突提示。

## Dry-run

默认不执行 `qm`，只打印命令：

```bash
bash scripts/pve/create-cloudinit-vm.sh --config inventory/vms/vm-k8s-01.yaml
```

检查输出顺序应为：

1. `qm clone`
2. `qm set --cores --memory`
3. `qm set --net0`
4. `qm set --ciuser --sshkeys`
5. `qm set --ipconfig0`
6. `qm resize`（如果设置了 `disk`）
7. `qm cloudinit update`
8. `qm start`（如果 `start: true`）

## Apply 创建 VM

确认 dry-run 输出无误后执行：

```bash
bash scripts/pve/create-cloudinit-vm.sh --config inventory/vms/vm-k8s-01.yaml --apply
```

脚本会在 apply 前检查目标 VMID 是否已存在。若中途失败，脚本不会自动 destroy VM，需要操作者手动判断是否清理。

## 创建后验证

```bash
qm status <vmid>
qm config <vmid>
```

如果 `start: true`：

```bash
qm terminal <vmid>
ssh <ci-user>@<vm-ip>
```

在 guest 内确认 Cloud-Init 完成：

```bash
cloud-init status --wait
ip addr
hostnamectl
```

## 回滚 / 清理

如果创建失败或配置错误，先确认 VM 是否承载了任何需要保留的数据。确认可删除后：

```bash
qm stop <vmid>
qm destroy <vmid> --purge 1
```

不要让脚本自动执行 destroy；VM 删除必须由操作者显式确认。

## 与项目文档的关系

- 设计决策：`docs/06-decisions/adr-0003-cloud-init-vm-template.md`
- IP 规划：`inventory/ips.md`
- Host 台账：`inventory/hosts.md`
- 示例配置：`inventory/vms/examples/cloudinit-vm.example.yaml`
