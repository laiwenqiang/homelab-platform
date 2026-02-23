# 架构（docs/01-architecture.md）

> 目标：把 homelab 按“小公司生产环境”的方式组织，让系统**可复现、可隔离、可恢复、可迭代**。  
> 基座：单机 PVE（Lenovo P3 Tiny：i7-13700T / 32GB RAM / 1TB NVMe）。  
> 日常工具：TrendRadar（Compose）、LobeChat（LXC）。
> 学习栈：K8s（k3s）+ GitOps + 可观测。  
> 高风险 AI：OpenClaw 独立 VM 隔离。


## 1. 总体架构视图

### 1.1 分层（从下到上）
1) **硬件层**
- Lenovo P3 Tiny（单机）
- 未来可扩展：64GB RAM、第二块 NVMe（提升可靠性/容量）

2) **虚拟化与底座层（PVE）**
- 负责：虚拟化、网络桥接、存储池、快照/备份策略、资源隔离
- 原则：PVE 宿主尽量“干净”，不承载业务服务

3) **网络与隔离层（逻辑分区）**
- mgmt：仅 PVE 管理访问
- tools：日常工具（稳定优先）
- lab：K8s 学习区（可重装、允许折腾）
- ai：高风险可执行 AI 区（强隔离、最小权限）

4) **服务承载层（VM/LXC/K8s）**
- LXC：日常工具（LobeChat）——低开销、快照回滚方便
- VM：K8s（k3s）——学习环境，可随时重建
- VM：OpenClaw（隔离）——安全边界清晰，可断网/可回滚

5) **平台能力层（能力中心）**
- 入口中心：统一域名/反代/TLS/访问控制（后续可加 SSO）
- 可观测中心：Prometheus/Grafana（+ Loki/告警）
- 交付中心：Git/GitOps（Argo CD）、CI/CD（后续）
- 数据中心：（后续）Postgres/Redis/MinIO
- 安全中心：最小权限、Secrets 管理（SOPS/Vault）、审计（后续）

## 2. 关键设计原则

### 2.1 稳定性优先级
- **tools（日常） > mgmt（基础） > lab（学习） > ai（可关停）**
- 日常工具不依赖 K8s；K8s 可以随时重装但不影响 RSS/Chat。

### 2.2 默认不信任（Zero Trust 心智）
- ai 区（OpenClaw）默认不可信：**独立 VM + 网络隔离 + 最小 RBAC**
- 不暴露 PVE 管理面到公网；外部访问优先 VPN/Zero Trust。

### 2.3 可恢复性优先
- 任何有状态组件必须明确：
  - 数据在哪里（目录/卷/PV）
  - 备份在哪里（离机）
  - 恢复怎么验证（演练记录）

### 2.4 变更可追溯
- 所有变更走 Issue/PR
- 关键选型写 ADR
- 操作步骤写 Runbook
- 台账（inventory）同步更新


## 3. 网络架构与流量路径

### 3.1 网段与角色（建议，最终以 docs/02-network.md 为准）
- **mgmt**：PVE 管理、SSH 管理、仅管理终端可达
- **tools**：TrendRadar、LobeChat、反代入口等日常服务
- **lab**：K8s（k3s）集群与学习用服务
- **ai**：OpenClaw（以及可选模型服务），对 mgmt 默认禁止

### 3.2 访问控制（原则级）
- tools -> lab：允许（访问 Grafana/ArgoCD 等）
- ai -> lab：**仅允许必要的目标与端口**（例如 K8s API/模型服务），其余禁止
- ai -> mgmt：默认禁止
- 外部访问：优先 VPN/Zero Trust；不直接端口映射 PVE 管理界面

### 3.3 统一入口（后续落地）
- 统一反代入口（例如 `proxy.tools.home`）
- 子域名：
  - `freshrss.tools.home`
  - `lobechat.tools.home`
  - `grafana.lab.home`
  - `argocd.lab.home`
- 原则：业务服务不直接暴露端口；统一走反代和访问控制


## 4. 计算承载规划（v1）

> 这是“运行时架构”的核心：什么放哪、为什么、边界是什么。  
> 资源分配的具体数值见对应 `[infra] VM/LXC 资源分配规划（v1）` Issue 与 inventory 台账。

### 4.1 必选组件（v1）

| 名称 | 类型 | 网段 | IP | 角色 | vCPU | RAM | Disk |
|------|------|------|----|------|-----:|----:|-----:|
| pve-01 | host | mgmt | 192.168.5.10 | 宿主机 | 2★ | 4GB★ | — |
| lxc-nginx-01 | LXC | tools | 192.168.5.20 | 反向代理 | 1 | 512MB | 8GB |
| lxc-adguard-01 | LXC | tools | 192.168.5.21 | DNS/AdGuard | 1 | 512MB | 8GB |
| lxc-monitor-01 | LXC | tools | 192.168.5.22 | Prometheus + Grafana | 2 | 2GB | 30GB |
| lxc-logging-01 | LXC | tools | 192.168.5.23 | Loki | 2 | 2GB | 30GB |
| lxc-trendradar-01 | LXC | tools | 192.168.5.31 | TrendRadar | 2 | 2GB | 30GB |
| lxc-lobechat-01 | LXC | tools | 192.168.5.32 | LobeChat | 2 | 3GB | 20GB |
| vm-k8s-01 | VM | lab | 192.168.5.50 | k3s 单节点（学习/GitOps） | 6 | 8GB | 100GB |
| vm-openclaw-01 | VM | ai | 192.168.5.81 | OpenClaw（隔离） | 4 | 6GB | 80GB |

> ★ 宿主机保留，不计入 Guest 分配。必选 RAM 合计 24GB，在 26GB 上限内。

### 4.2 可选组件（按需部署）
- **vm-openwrt-01（VM, tools, .30）**：实验路由，仅网络实验时创建
- **vm-model-01（VM, ai, .80）**：Ollama 模型服务，与 vm-openclaw-01 不可同时满载，默认关机

### 4.3 放置策略（为什么这么放）
- **可观测栈放 tools 区独立 LXC**：与日常工具同等稳定性要求，维护更直观，不依赖 K8s 可用性
- **LobeChat 放 LXC**：日常访问高频，快照回滚简单，维护成本低
- **TrendRadar 用 Compose**：依赖 DB/卷，Compose 足够稳定；日常工具不绑 K8s
- **K8s 单独 VM**：学习环境允许推倒重来；把”学习复杂度”隔离在 lab
- **OpenClaw 独立 VM**：可执行型 Agent 高风险，边界必须清晰，可一键断网/回滚


## 5. 平台能力与“能力中心”规划

### 5.1 GitOps/交付中心（lab）
- 目标：任何跑在 K8s 的东西，都用 Git 声明式管理
- 组件（规划）：
  - Argo CD（GitOps）
  - （后续）CI/CD：Gitea/GitLab + Runner
  - （后续）镜像仓库：Harbor 或轻量 registry

### 5.2 可观测中心（lab）
- v1：Prometheus + Grafana
- v1.1：Loki（日志）+ 告警通道（ntfy/Telegram）
- v2：Tempo/Jaeger + OpenTelemetry（链路追踪）

### 5.3 数据中心（后续）
- v1（可选）：Postgres / Redis（优先满足你自己的 demo 服务）
- v2：MinIO（对象存储，用于备份/归档/模型文件）

### 5.4 安全中心（规划）
- v1：网络隔离 + 最小权限 + 不暴露管理面
- v2：SSO（Keycloak/Authelia）
- v2：Secrets（SOPS 起步 -> Vault）


## 6. 数据、状态与备份策略（架构约束）

### 6.1 数据分类
- 配置类（Git）：本仓库文件（docs、compose、manifests、台账）
- 服务状态类：
  - TrendRadar：Postgres 数据卷 + TrendRadar data/extensions
  - LobeChat：依赖的数据目录/DB（按你的部署方式确定）
  - K8s：关键 PV（如果有），以及 GitOps 仓库为主
- AI/模型类：
  - OpenClaw：配置、skills（白名单）、运行日志
  - 模型文件：体积大，需明确存放位置与配额

### 6.2 备份与恢复（强制要求）
- PVE 层：VM/LXC 定期备份到**离机目标**（外置盘/NAS）
- 服务层：有状态卷明确备份策略
- 演练：每月一次恢复演练，记录到 `docs/05-runbooks/backup-restore-drill.md`


## 7. 安全边界（尤其是 OpenClaw）

- OpenClaw 必须在 ai 网段独立 VM
- 默认：
  - 禁止 ai -> mgmt
  - ai -> lab 仅允许最小目标（例如 K8s API）与最小权限（最小 RBAC）
- skills/扩展采取白名单策略；任何需要复制粘贴 shell 的“教程”都要当作高风险处理
- 快照策略：
  - 上线前快照（pre-openclaw-v1）
  - 每次新增 skills 前快照（pre-skill-xxx）

> 更具体的隔离策略见：`docs/06-decisions/adr-0002-openclaw-isolation.md`


## 8. 版本化与演进计划

### v1（当前）
- PVE 基座 + 网络分区初版
- tools：TrendRadar（Compose）、LobeChat（LXC）
- lab：k3s 单节点（学习 + 观测）
- ai：OpenClaw 独立 VM

### v1.1（短期优化）
- 统一反代入口 + TLS
- Loki + 告警通道
- 资源分配复盘（v1.1）

### v2（中期进阶）
- SSO（Keycloak/Authelia）
- Secrets（SOPS -> Vault）
- MinIO + 更体系化备份


## 9. 关联文档
- 网络规划：`docs/02-network.md`
- 存储与备份：`docs/03-storage-backup.md`
- 安全基线：`docs/04-security.md`
- ADR：
  - `docs/06-decisions/adr-0001-daily-tools-placement.md`
  - `docs/06-decisions/adr-0002-openclaw-isolation.md`
- Runbooks：
  - `docs/05-runbooks/service-deploy-lxc.md`
  - `docs/05-runbooks/backup-restore-drill.md`
