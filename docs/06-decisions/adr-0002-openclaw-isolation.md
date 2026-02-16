# ADR-0002: OpenClaw 等可执行 AI 的隔离策略

- Status: Proposed
- Date: 2026-02-15

## Context
可执行型 AI/Agent 可能拥有运行命令、安装扩展、访问内部服务的能力，属于高风险工作负载。

## Decision
- OpenClaw 独立 VM 部署
- 网络：放置在 ai 网段；默认禁止访问 mgmt；仅允许访问 lab 中 K8s API（最小端口）
- 权限：K8s 使用最小 RBAC token；skills/扩展采用白名单策略

## Consequences
- 优点：降低横向移动风险；支持快照回滚；边界清晰
- 代价：增加一台 VM 的资源与运维成本

## Alternatives considered
- 与 tools 区同机/同网段：风险过高
- 直接部署在 PVE 宿主：不允许（宿主必须保持干净）

## Rollback plan
- 直接断开 ai 网段到其他网段的访问
- VM 回滚快照/重建
