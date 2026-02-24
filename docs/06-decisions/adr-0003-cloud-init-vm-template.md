# ADR-0003: 在 Homelab 中采用 Cloud-Init VM 模板作为标准创建方式

- Status: Accepted
- Date: 2026-02-24

## Context
在 Homelab 环境中，需要频繁创建多个相同的 Linux 虚拟机（Debian 13）。传统通过 ISO 手动安装方式存在以下问题：

- 安装时间长（20~40 分钟）
- 依赖外部镜像源（网络波动影响大）
- 每次重复配置用户、网络、SSH
- 难以批量部署
- 易产生配置漂移（Configuration Drift）

目标：

- 支持快速批量创建 VM
- 支持固定 IP 或 DHCP
- 强制 SSH Key 登录
- 可重复、可版本化
- 具备自动化扩展能力

## Decision

### 1. 使用 Debian Cloud Image + Cloud-Init 模板机制

采用官方 Cloud Image（qcow2），导入 PVE 并制作标准模板。标准流程：

1. `qm importdisk`
2. 使用 VirtIO SCSI 磁盘
3. 添加 CloudInit Drive（IDE）
4. 添加 Serial Port（serial0）
5. 设置 Boot Order → scsi0 优先
6. 首次启动 → 确认系统正常后，执行模板清理（转换模板前的必需步骤）：
   - `cloud-init clean`（清除实例化状态，确保克隆后重新执行 Cloud-Init）
   - `truncate -s 0 /etc/machine-id`（避免克隆后 DHCP 冲突）
   - 关机
7. Convert to Template

模板保持“无状态”，实例在克隆时注入配置。

### 2. 标准克隆流程

克隆步骤：

1. Clone（Full Clone）
2. 设置 Cloud-Init：
   - IP（DHCP 或 Static，参照 [02-network.md](../02-network.md) 中的网段规划）
   - 非 root 用户（推荐统一使用 `debian` 或自定义的标准运维用户名）
   - SSH public key
3. Regenerate Image
4. 启动 VM

### 3. SSH 登录策略

统一采用：

- 禁止 root SSH
- 禁止密码登录
- 仅允许 SSH Key

所有实例统一通过 Cloud-Init 注入公钥。

### 4. IP 分配策略

模板不固化 IP。IP 在克隆阶段注入，例如：
`--ipconfig0 ip=192.168.5.X/24,gw=192.168.5.1`

支持三种模式：

- UI 手动指定
- CLI 批量自动递增
- DHCP + MAC 绑定

### 5. 磁盘策略

Cloud Image 默认 3G 磁盘过小。扩容流程：

1. PVE Resize Disk（Web UI 或 `qm resize <vmid> scsi0 +17G`）
2. VM 内执行：
`growpart /dev/sda 1`
`resize2fs /dev/sda1`

### 6. VM 与 LXC 使用边界

VM 为标准计算节点方案，LXC 为轻量服务补充。具体使用边界和实例分配参见：

- [ADR-0001: Daily Tools Placement](adr-0001-daily-tools-placement.md)
- [01-architecture.md](../01-architecture.md)（4.1–4.3 节）

## Consequences

### 收益

- 新 VM 创建时间从 20 分钟降至 1 分钟
- 支持批量自动部署
- 系统一致性提升
- SSH 安全性提升
- 可脚本化管理
- 为 GitOps 演进奠定基础

### 代价

- 需要理解 Cloud-Init 工作机制
- 模板需要维护
- 扩容需额外步骤
- Windows 不适用该方案

### 风险

- 未执行 `cloud-init clean` → 克隆异常
- 忘记 Regenerate → 配置未更新
- 未清理 machine-id → DHCP 冲突
- Boot Order 错误 → 无法启动

## Alternatives considered

### 1. ISO 手动安装

优点：
- 简单

缺点：
- 慢
- 不可批量
- 难以保持一致性

未选。

### 2. 仅使用 LXC 模板

优点：
- 轻量
- 启动快

缺点：
- 无独立内核
- Docker/K8s 支持不稳定
- 隔离弱

作为补充方案，不作为标准。

### 3. 纯 DHCP 分配，不使用 Cloud-Init

优点：
- 简单

缺点：
- 无法自动注入用户/密钥
- 无法自动化管理
- 不可版本化

未选。

### 4. 直接使用 Terraform 管理 PVE

优点：
- 完全 IaC
- 可规模化

缺点：
- 对当前 Homelab 复杂度过高

暂缓。

## Rollback plan

如需回退：

1. 保留原 ISO 安装方式作为备选
2. 删除 Cloud-Init Template
3. 或改为 LXC 为主方案

该决策无破坏性数据变更，可安全回退。

## Summary

本决策将 Homelab 从：

> 手动实验环境

升级为：

> 可重复、可扩展、可自动化的小型私有云架构。