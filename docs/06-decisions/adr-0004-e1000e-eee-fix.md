# ADR-0004: e1000e NIC 稳定性修复方案

- Status: Accepted
- Date: 2026-03-08

## Context

PVE 宿主机（Lenovo ThinkStation P3 Tiny）搭载 Intel I219 系列网卡，使用 e1000e 内核驱动。系统稳定运行约两周后，突然出现网络异常——路由器显示 PVE 主机在线，但所有服务均无法访问。首次通过重启恢复，约 2 小时后问题再次复现。

排查 syslog 确认错误为 `e1000e ... Detected Hardware Unit Hang`，根因是 EEE（Energy Efficient Ethernet）在低流量时触发网卡进入低功耗状态，e1000e 驱动在状态切换时存在 race condition，导致 DMA 传输超时、内核判定硬件挂起。此外社区大量案例表明 NIC offloading（TSO/GSO/GRO）也是触发因素之一。

此为 Intel I219 系列的已知缺陷，上游尚未彻底修复。需要选择一种方式将修复配置持久化。

## Decision

采用**单一 systemd 服务**（`e1000e-guard.service`），合并两项职责：

1. **启动时硬化**：关闭 EEE + 关闭 NIC offloading（TSO/GSO/GRO）
2. **常驻监控**：ping 网关检测挂起，连续 3 次失败自动 reset 网卡并重新应用硬化配置

合并理由：
- watchdog 恢复后必须重新应用硬化配置，两者本就紧密耦合
- 社区主流做法也是单脚本方案，未见拆分为多服务的实践
- 个人 homelab 场景，单服务更易维护

关闭 EEE 和 offloading 对 homelab 场景无负面影响：
- 功耗影响极小（网口省电约 0.1-0.5W），对 35W TDP 的 i7-13700T 可忽略
- 关闭后网络延迟反而更低（无 wake-up 和 offloading 开销）
- 服务器 24/7 运行，省电模式本就不应启用

## Consequences

**收益：**
- 一个服务覆盖修复 + 监控，运维简单
- 配置独立于 PVE 网络配置，不会因 Web UI 操作而丢失
- 通过 `systemctl status` 和 `journalctl` 可查看完整状态和历史
- watchdog 提供自动恢复能力，减少人工干预

**代价：**
- 无法独立启停硬化和监控（如需临时关闭 watchdog 但保留硬化，需手动执行 ethtool）
- watchdog 存在误判可能（已通过 3 次连续失败阈值 / 90s 容忍窗口缓解）

## Alternatives considered

### 持久化方式

| 维度 | `/etc/network/interfaces` | systemd 服务 (chosen) | udev 规则 |
|------|--------------------------|----------------------|-----------|
| **PVE 兼容性** | PVE Web UI 会覆写该文件 | 独立文件，不受影响 | 独立文件，不受影响 |
| **可观测性** | 无状态、无日志 | systemctl status + journald | 仅 journald |
| **调试便利性** | 需手动执行命令 | systemctl restart 即可 | 需 udevadm trigger |

### 服务架构

| 维度 | 合并为一个服务 (chosen) | 拆分为两个服务 |
|------|------------------------|---------------|
| **耦合度** | 天然耦合（reset 后需重新硬化） | 人为拆分紧耦合逻辑 |
| **社区实践** | 与主流单脚本方案一致 | 未见社区采用 |
| **独立启停** | 不支持 | 支持 |
| **适用场景** | 个人 homelab | 多人运维团队 |

## Rollback plan

1. 停止并禁用服务：`systemctl disable --now e1000e-guard`
2. 恢复 `/etc/network/interfaces` 中的 `post-up ethtool --set-eee enp0s31f6 eee off`
3. 重载网络：`ifreload -a`
