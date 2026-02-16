# 概览

## 硬件说明
- 机器型号:Lenovo Thinkstation P3 tiny
- 详细配置:i7-13700T (16C/24T, 35W TDP) + 32GB RAM + 1TB SSD

## 你在搭什么
把家庭实验环境按“小公司生产环境”方式组织：
- 基座：PVE（虚拟化、网络、存储、备份）
- 工具区：LXC/VM 承载日常工具（FreshRSS、LobeChat、反代等）
- 学习区：K8s（用于 DevOps/K8s 学习，允许重装/回滚）
- 隔离区：高风险可执行 AI（OpenClaw 等）独立 VM

## 最重要的三件事
1) 外部备份（必须离开这台机器）
2) 网络隔离（至少 mgmt / lab / tools / ai）
3) 变更可追溯（Issue/PR/ADR/Runbook）

## 本仓库交付物
- 可复现的服务定义（Compose/清单）
- 明确的架构与决策记录（ADR）
- 可执行的运维手册（Runbook）
- 资产台账（inventory）
