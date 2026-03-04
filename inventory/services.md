# Services

| Service | Host | Deploy | Data | Backup | URL |
|---|---|---|---|---|---|
| Nginx/Caddy | lxc-nginx-01 (tools) | systemd | — | — | proxy.tools.home |
| AdGuard Home | lxc-adguard-01 (tools) | docker | volume | yes | adguard.tools.home |
| Prometheus + Grafana | lxc-monitor-01 (tools) | docker-compose | volume | yes | grafana.tools.home |
| Loki | lxc-logging-01 (tools) | docker-compose | volume | yes | — |
| TrendRadar | lxc-trendradar-01 (tools) | docker-compose | volume | yes | trendradar.tools.home |
| LobeChat | lxc-lobechat-01 (tools) | systemd/docker | volume | yes | lobechat.tools.home |
| k3s (GitOps) | vm-k8s-01 (lab) | kubeadm/k3s | PV | yes | argocd.lab.home |
| OpenClaw | vm-openclaw-01 (ai) | systemd/docker | volume | yes | — |
| Ollama | vm-model-01 (ai, 可选) | systemd | volume | — | llm.ai.home |
| OpenWrt | vm-openwrt-01 (tools, 可选) | — | — | — | — |
