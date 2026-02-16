---
name: Infra
about: PVE / 网络 / 存储 / 备份 等基础设施变更
title: "[infra] "
labels: ["type:infra"]
---

> 目标：任何 infra 变更都必须可回滚、可恢复、可审计。  
> 提醒：涉及关键选型/策略请补 ADR；涉及具体操作步骤请补 Runbook。  
> 注意：不要在 Issue 里写真实 secrets（密码/Token/Key），只写占位或引用 secrets 文件。

## 目标（Goal）
- 

## 背景（Context）
- 

## 范围（Scope）
**做：**
- [ ] 

**不做：**
- [ ] 

## 领域（Area）
- [ ] PVE 基线/升级
- [ ] 网络（网段/VLAN/桥接/防火墙）
- [ ] 存储（LVM/ZFS/磁盘/IO）
- [ ] 备份与恢复（PVE Backup/PBS/外置/NAS）
- [ ] 其他：

## 方案设计（Design）
（高层设计 + 关键参数，尽量可执行）
- 网段/规划：
- 访问控制：
- 存储方案：
- 备份策略：
- 变更窗口（如需）：

## 验收标准（DoD / Acceptance）
（可验证、可复现，最好给出验证方式/证据点）
- [ ] 
- [ ] 
- [ ] 

## 风险与影响（Risks & Impact）
（会影响哪些服务？最坏会怎样？）
- 影响范围：
- 最坏情况：
- 预防措施：

## 回滚方案（Rollback Plan）
（明确触发条件 + 回滚步骤）
**触发条件：**
- 

**回滚步骤：**
1. 
2. 
3. 

## 需要补的文档（Docs to update）
- [ ] docs/02-network.md
- [ ] docs/03-storage-backup.md
- [ ] docs/06-decisions/adr-xxxx-*.md（如涉及关键决策）
- [ ] docs/05-runbooks/*.md（如涉及操作流程）

## 子任务拆分（Tasks）
（按依赖顺序）
- [ ] 备份/快照
- [ ] 变更实施
- [ ] 验证与验收
- [ ] 演练/复盘（如适用）
- [ ] 文档更新
