# 安全基线

## 原则
- 默认不信任（尤其是可执行 AI/插件/扩展）
- 最小权限（账号、token、网络访问都最小化）
- 审计与可追溯（变更记录、登录、关键操作）

## 立即要做的事
- PVE：仅 mgmt 网段可访问；禁止公网暴露
- SSH：禁密码登录（仅 key），必要时加 Fail2ban
- Secrets：不进 Git（用 .env.example、secrets.example.md 占位）
- OpenClaw：独立 VM + 网络隔离 + skills 白名单（见 ADR）

## 后续增强（路线）
- SSO（Keycloak/Authelia）
- Secrets 管理（SOPS 起步 -> Vault）
- 安全扫描（Trivy 等）
