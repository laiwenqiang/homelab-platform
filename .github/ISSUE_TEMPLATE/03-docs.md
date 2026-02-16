---
name: Docs
about: 补齐文档 / ADR / Runbook / 图示 / 复盘记录
title: "[docs] "
labels: ["type:docs"]
---

> 目标：让“未来的你”或“面试官”看得懂、照着做得出来。  
> 文档应尽量可验证：关键参数、命令、截图/日志证据点（可选）。

## 文档类型（Doc Type）
- [ ] 架构文档（overview/architecture）
- [ ] 网络/存储/备份规范
- [ ] ADR（决策记录）
- [ ] Runbook（可执行手册）
- [ ] 复盘（incident/演练）
- [ ] 其他：

## 目标（Goal）
- 

## 背景（Context）
- 

## 范围（Scope）
**包含：**
- [ ] 关键决策与理由
- [ ] 关键参数（网段、端口、资源）
- [ ] 操作步骤（如 Runbook）
- [ ] 验证方式/证据点（如适用）

**不包含：**
- [ ] 

## 目标文件（Files）
（列出要新增/修改的文件路径）
- [ ] docs/00-overview.md
- [ ] docs/01-architecture.md
- [ ] docs/02-network.md
- [ ] docs/03-storage-backup.md
- [ ] docs/04-security.md
- [ ] docs/06-decisions/adr-xxxx-*.md
- [ ] docs/05-runbooks/*.md
- [ ] 其他：

## 验收标准（DoD / Acceptance）
- [ ] 文档结构符合模板（ADR/Runbook）
- [ ] 参数与步骤可复现（别人照做能跑通）
- [ ] 与 inventory/ 台账一致（IP/域名/服务）
- [ ] 需要的链接/截图/日志说明已补齐（可选）

## 子任务拆分（Tasks）
- [ ] 收集现有配置参数
- [ ] 按模板补齐内容
- [ ] 与台账对齐（hosts/ips/domains/services）
- [ ] PR 自检与合并
