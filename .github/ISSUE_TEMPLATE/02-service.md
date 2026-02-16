---
name: Service
about: 部署/升级/迁移某个服务（FreshRSS、LobeChat 等）
title: "[service] "
labels: ["type:service"]
---

> 目标：服务上线必须可访问、可观测（至少日志）、可回滚、可备份。  
> 注意：不要在 Issue 里写真实 secrets（密码/Token/Key），只写占位或引用 secrets 文件。

## 服务名称（Service）
- 

## 部署位置（Location）
- [ ] LXC（tools 区）
- [ ] VM（tools 区）
- [ ] K8s（lab 区）
- [ ] VM（ai 隔离区）
- [ ] 其他：

## 目标（Goal）
- 

## 部署方案（Design）
（写清楚：运行方式、依赖、端口、数据卷、域名、反代、资源）
- 运行方式（docker compose / systemd / helm）：
- 依赖（DB/Redis/对象存储等）：
- 端口与访问方式：
- 域名与反代（如有）：
- 数据落盘位置（目录/卷）：
- 资源（CPU/MEM/Disk）：

## 数据与备份（Data & Backup）
（哪些是有状态数据？怎么备份？恢复怎么验证？）
- 数据目录/卷：
- 备份频率：
- 恢复验证步骤：

## 可观测性（Observability）
（至少写日志；可选 metrics/healthcheck）
- 日志获取方式（docker logs / journald / Loki）：
- 健康检查（如有）：
- 指标（如有）：

## 安全（Security）
（账号、权限、网络可达范围、是否需要 SSO、最小权限）
- 访问范围（仅内网/特定网段）：
- 管理端口暴露策略：
- secrets 管理方式（.env 不入库 / SOPS / Vault 等）：

## 验收标准（DoD / Acceptance）
- [ ] 域名或端口可访问（HTTPS 如适用）
- [ ] 重启后自启动
- [ ] 数据持久化验证（重启后数据仍在）
- [ ] 纳入备份并完成一次恢复验证（或记录演练计划）
- [ ] 文档更新（services/.../README.md + runbook）

## 回滚方案（Rollback Plan）
- LXC/VM：回滚快照（快照名：__________）
- Compose：回退镜像 tag/恢复数据卷
- K8s：Git 回滚 + ArgoCD 同步

## 子任务拆分（Tasks）
- [ ] 准备运行环境（LXC/VM/K8s namespace）
- [ ] 部署服务（compose/helm/systemd）
- [ ] 配置反代与域名（如需）
- [ ] 纳入备份
- [ ] 验收与记录
