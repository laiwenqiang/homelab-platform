homelab-platform

目标：把 PVE Homelab 的建设过程做成“可复现、可审计、可恢复”的工程项目。

## 核心原则
- 配置即代码：网络/存储/服务参数写进 Git
- 变更走 PR：哪怕只有一个人，也必须走 PR 和模板
- 备份与演练：每月至少 1 次恢复演练，并记录在 runbook

## 当前约束/决策（摘要）
- 虚拟化基座：PVE
- 日常工具：
  - FreshRSS：Docker Compose 部署（运行在工具区 VM/LXC 里）
  - LobeChat：运行在 LXC（不进 K8s）
- 高风险/可执行型 AI（如 OpenClaw）：独立 VM 隔离（见 ADR）

## 快速导航
- 概览：docs/00-overview.md
- 架构：docs/01-architecture.md
- 网络：docs/02-network.md
- 存储与备份：docs/03-storage-backup.md
- 安全：docs/04-security.md
- ADR：docs/06-decisions/
- Runbooks：docs/05-runbooks/
- 服务清单：inventory/services.md
- 规划：plan/roadmap.md、plan/milestones.md

## 工作方式
1. 开 Issue（写清楚目标、验收、风险、回滚）
2. 建分支 -> 提交变更 -> 提 PR
3. PR 自检：文档、配置、备份影响、回滚路径
4. 合并后在 runbook 记录上线与演练结果

## 目录约定
- services/：可部署的服务定义（Compose/Helm/清单）
- docs/：架构/流程/决策/手册
- inventory/：资产台账、IP、域名、服务、账号占位
- scripts/：校验/辅助脚本
