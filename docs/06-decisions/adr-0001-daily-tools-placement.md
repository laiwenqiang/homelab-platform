# ADR-0001: 日常工具部署位置（FreshRSS / LobeChat）

- Status: Accepted
- Date: 2026-02-15

## Context
需要在 homelab 增加日常工具服务（RSS 聚合、LobeChat），要求稳定、维护成本低，并与 K8s 学习环境解耦。

## Decision
- FreshRSS：使用 Docker Compose 部署（运行在工具区 VM/LXC）
- LobeChat：运行在 LXC（不放进 K8s）

## Consequences
- 优点：日常工具不受 K8s 折腾影响；升级/回滚更简单；资源开销小
- 代价：需要单独管理 LXC/Compose 生命周期与备份

## Alternatives considered
- 全部上 K8s：学习价值高，但日常可用性下降、维护复杂度增加

## Rollback plan
- LobeChat：LXC 快照回滚
- FreshRSS：Compose 回滚到上一版本镜像 + 数据卷恢复
