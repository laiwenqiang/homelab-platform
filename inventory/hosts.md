# Hosts

## 相关组件（v1 基线）

| Name | Type | Purpose | Network | IP | vCPU | RAM | Disk |
|---|---|---|---|---|---:|---:|---:|
| pve-01 | bare-metal | 宿主机（Hypervisor） | mgmt | 192.168.5.10 | 2★ | 4GB★ | — |
| lxc-nginx-01 | LXC | 反向代理（Nginx/Caddy） | tools | 192.168.5.20 | 1 | 512MB | 8GB |
| lxc-adguard-01 | LXC | DNS / AdGuard | tools | 192.168.5.21 | 1 | 512MB | 8GB |
| lxc-monitor-01 | LXC | Prometheus + Grafana | tools | 192.168.5.22 | 2 | 2GB | 30GB |
| lxc-logging-01 | LXC | Loki | tools | 192.168.5.23 | 2 | 2GB | 30GB |
| vm-openwrt-01 | VM | 实验路由（OpenWrt） | tools | 192.168.5.30 | 1 | 512MB | 4GB |
| lxc-trendradar-01 | LXC | TrendRadar | tools | 192.168.5.31 | 2 | 2GB | 30GB |
| lxc-lobechat-01 | LXC | LobeChat | tools | 192.168.5.32 | 2 | 3GB | 20GB |
| vm-k8s-01 | VM | k3s 单节点（学习/GitOps） | lab | 192.168.5.50 | 6 | 8GB | 100GB |
| vm-model-01 | VM | Ollama 模型服务 | ai | 192.168.5.80 | 4 | 6GB | 120GB |
| vm-openclaw-01 | VM | OpenClaw（隔离 AI Agent） | ai | 192.168.5.81 | 4 | 6GB | 80GB |

> ★ 宿主机保留资源，不计入 Guest 分配总量。
> vm-openwrt-01、vm-model-01为可选，按需部署。
> vm-model-01 与 vm-openclaw-01 不可同时满载运行，默认关机按需启动。

## 资源汇总

| 项目 | 必选合计 | +可选全部 | 上限 |
|------|--------:|----------:|-----:|
| RAM | 24GB ✓ | 30.5GB ⚠ | 26GB |
| Disk | ~306GB | ~430GB | ~750GB ✓ |
