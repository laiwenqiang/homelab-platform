# LobeChat on LXC

## 决策
LobeChat 运行在 LXC（tools 网段），不进入 K8s。

## 最小交付
- LXC 创建参数记录（CPU/MEM/Disk/IP）
- 服务自启动（systemd 或 docker）
- 反代接入：lobechat.tools.home
- 快照：pre-lobechat-v1
- 备份：配置 + 数据目录/volume

## 上线流程
见 docs/05-runbooks/service-deploy-lxc.md
