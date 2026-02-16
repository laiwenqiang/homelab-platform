# 架构

## 逻辑分区（建议）
- mgmt：PVE 管理网段（仅管理用途）
- tools：日常工具区（FreshRSS、LobeChat、反代等）
- lab：K8s 学习区（可随时重建）
- ai：高风险 AI 执行区（独立 VM，最小权限）

## 计算承载（建议）
- LXC：LobeChat（稳定、低开销、好维护）
- VM/LXC：FreshRSS（Compose）
- VM：K8s（k3s 或 kubeadm）
- VM：OpenClaw（隔离 + 受控访问 K8s API）

## 对外/对内访问策略（先写原则）
- 默认仅内网访问
- 如需外部访问：优先 Zero Trust/VPN（不做端口暴露）
- 所有 Web 服务统一入口（反代 + TLS）+ 访问控制
