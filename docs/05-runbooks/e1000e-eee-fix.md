# e1000e NIC 稳定性修复部署手册

> 适用于：PVE 宿主机（Lenovo ThinkStation P3 Tiny / Intel I219 网卡）
> 关联决策：[ADR-0004](../06-decisions/adr-0004-e1000e-eee-fix.md)
> 关联 Issue：[#8](https://github.com/laiwenqiang/homelab-platform/issues/8)

## 前置条件

- PVE 宿主机 root 权限
- 已安装 `ethtool`（PVE 默认已包含）
- 配置文件位于本仓库 `infra/pve-host/e1000e/` 目录

## 部署步骤

### 1. 部署 e1000e-guard 服务

```bash
# 复制脚本并赋权
cp infra/pve-host/e1000e/e1000e-watchdog.sh /usr/local/bin/
chmod +x /usr/local/bin/e1000e-watchdog.sh

# 复制 service 文件
cp infra/pve-host/e1000e/e1000e-guard.service /etc/systemd/system/

# 如需按当前宿主机接口名调整：
# ExecStart=/usr/local/bin/e1000e-watchdog.sh enp0s31f6 vmbr0 192.168.5.1

# 启用并启动
systemctl daemon-reload
systemctl enable --now e1000e-guard.service
```

### 2. 验证

```bash
# 服务状态
systemctl status e1000e-guard
# 期望：Active: active (running)

# 查看启动日志
journalctl -t e1000e-guard --no-pager -n 10
# 期望：看到 "EEE disabled" + "TSO/GSO/GRO offloading disabled" + "entering watchdog mode"

# 确认 EEE 已关闭
ethtool --show-eee enp0s31f6
# 期望：EEE status: disabled

# 确认 offloading 已关闭
ethtool -k enp0s31f6 | grep -E "tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload"
# 期望：均为 off
```

### 3. 清理旧配置

```bash
# 备份
cp /etc/network/interfaces /etc/network/interfaces.bak.$(date +%Y%m%d)

# 编辑文件，移除类似以下内容：
# post-up /usr/sbin/ethtool --set-eee enp0s31f6 eee off
vi /etc/network/interfaces
```

### 4. 重启验证

```bash
reboot

# 重启后检查
systemctl status e1000e-guard       # active (running)
ethtool --show-eee enp0s31f6         # EEE disabled
ethtool -k enp0s31f6 | grep offload  # 相关项均为 off
```

## 日常运维

```bash
# 实时跟踪日志
journalctl -t e1000e-guard -f

# 当天日志
journalctl -t e1000e-guard --since today

# 查看是否发生过自动恢复
journalctl -t e1000e-guard | grep CRITICAL
```

## 回滚步骤

```bash
# 1. 停止并禁用服务
systemctl disable --now e1000e-guard

# 2. 恢复旧配置
cp /etc/network/interfaces.bak.* /etc/network/interfaces
# 或手动添加：post-up /usr/sbin/ethtool --set-eee enp0s31f6 eee off

# 3. 重载网络
ifreload -a
```
