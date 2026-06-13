# Monitoring 上线 Runbook（Prometheus + Grafana）

## 目标

在 `lxc-monitor-01` 上正式部署 `services/monitoring`，上线 Prometheus + Grafana 监控入口，并在真实 HomeLab 环境验证无误后再将 Monitor PR 标记为 Ready / 合并。

## 适用范围

- 服务：Prometheus + Grafana
- Host：`lxc-monitor-01`
- IP：`192.168.5.22`
- Zone：`tools`
- URL：`grafana.tools.home`
- 代码目录：`services/monitoring/`

本次包含：Prometheus/Grafana 基础栈、Prometheus self-scrape、通过 file_sd 管理的 node_exporter 多主机 scrape targets。

本次不包含：node_exporter 自动安装与生命周期管理、cAdvisor、Loki、Alertmanager。

## PR 门禁

Monitor PR 必须保持 Draft，直到以下条件全部完成：

- [ ] 在真实 `lxc-monitor-01` 上完成部署。
- [ ] `docker compose config` 通过。
- [ ] Prometheus self-scrape 正常。
- [ ] node_exporter target 文件加载正常；已部署 exporter 的机器显示 `up=1`。
- [ ] Grafana 能登录，Prometheus datasource 正常。
- [ ] `grafana.tools.home` 可通过内网入口访问。
- [ ] 重启 LXC 后服务自动恢复。
- [ ] `prometheus_data` 和 `grafana_data` 已纳入备份确认。
- [ ] 记录一次上线结果和必要的恢复演练记录。

## 上线前准备

### 1. 确认 PR 内容

在本地或管理机确认 Monitor PR 只包含：

- `services/monitoring/**`
- `docs/01-architecture.md`
- `docs/05-runbooks/monitoring-deploy.md`

不应包含 baseline、OpenClaw、Trellis workspace、临时文件或本地密钥。

### 2. 准备 LXC

在 PVE 中确认 `lxc-monitor-01`：

- IP：`192.168.5.22`
- 资源：2 vCPU / 2GB RAM / 30GB Disk
- 网络：tools 区
- 已完成基础初始化
- 已安装 Docker 和 Docker Compose plugin

检查命令：

```bash
hostnamectl
ip addr
docker version
docker compose version
```

### 3. 上线前快照

在 PVE 给 `lxc-monitor-01` 创建快照：

```text
pre-monitoring-v1
```

快照失败时停止上线。

## 部署步骤

### 1. 获取代码

在 `lxc-monitor-01` 上执行：

```bash
sudo mkdir -p /opt/homelab-platform
sudo chown "$USER:$USER" /opt/homelab-platform
cd /opt/homelab-platform
```

如果目录为空：

```bash
git clone https://github.com/laiwenqiang/homelab-platform.git .
git fetch origin
git switch feature/prometheus-monitoring-only
```

如果目录已存在：

```bash
git fetch origin
git switch feature/prometheus-monitoring-only
git pull --ff-only
```

### 2. 配置本地环境变量

```bash
cd /opt/homelab-platform/services/monitoring
umask 077
touch .env
chmod 600 .env
nano .env
```

在 `.env` 中设置：

- `GF_SECURITY_ADMIN_USER`，可选，默认 `admin`
- `GF_SECURITY_ADMIN_PASSWORD`，必填，使用强密码

`.env` 不提交到 Git。

### 3. 准备基础主机指标采集

Prometheus 从 `prometheus/targets/node-exporter.yml` 加载 HomeLab 主机采集目标。每个目标默认监听 `9100/tcp`。

Debian / PVE / Debian LXC / Debian VM 示例：

```bash
sudo apt update
sudo apt install prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
sudo systemctl status prometheus-node-exporter
```

OpenWrt 23.05.x / x86_64 示例：

1. 在管理机下载 Prometheus 官方 `node_exporter` `linux-amd64` release 包和 `sha256sums.txt`，校验 checksum 后解压。
2. 上传静态二进制到 OpenWrt：

```bash
scp node_exporter root@192.168.5.30:/tmp/node_exporter
```

3. 在 OpenWrt 上安装并配置 procd 服务：

```sh
cp /tmp/node_exporter /usr/sbin/node_exporter
chmod 0755 /usr/sbin/node_exporter
cat >/etc/init.d/node_exporter <<'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10
USE_PROCD=1

start_service() {
    procd_open_instance
    procd_set_param command /usr/sbin/node_exporter --web.listen-address=:9100
    procd_set_param respawn
    procd_close_instance
}
EOF
chmod 0755 /etc/init.d/node_exporter
/etc/init.d/node_exporter enable
/etc/init.d/node_exporter restart
```

安装后在被采集机器上验证：

```bash
curl -fsS http://localhost:9100/metrics >/dev/null
```

OpenWrt 可用：

```sh
wget -qO- http://127.0.0.1:9100/metrics >/dev/null
ls -l /etc/rc.d/S99node_exporter
```

从 `lxc-monitor-01` 验证网络连通：

```bash
curl -fsS http://192.168.5.10:9100/metrics >/dev/null
```

防火墙应只允许 `192.168.5.22` 访问各机器的 `9100/tcp`。规划中但尚未创建、未开机或未安装 exporter 的机器会在 Prometheus targets 中显示为 `down`。

### 4. 校验 Compose 配置

```bash
docker compose config
```

失败时不要启动服务，先修正配置或回滚。

### 5. 启动服务

```bash
docker compose up -d
docker compose ps
```

预期：

- `monitoring-prometheus` 为 running
- `monitoring-grafana` 为 running

## 验证步骤

### 1. 容器日志

```bash
docker compose logs --tail=100 prometheus
docker compose logs --tail=100 grafana
```

失败判定：

- Grafana 因密码变量缺失退出
- Prometheus 配置解析失败
- 容器反复 restart

### 2. Prometheus 配置与查询

```bash
docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
docker compose exec prometheus promtool query instant http://localhost:9090 'up{job="prometheus"}'
docker compose exec prometheus promtool query instant http://localhost:9090 'up{job="node_exporter"}'
```

预期：Prometheus self-scrape 目标值为 `1`；已安装并连通 node_exporter 的 HomeLab 机器值为 `1`，尚未部署 exporter 的规划机器可暂时为 `0`。

### 3. Grafana 本机访问

在管理电脑访问：

```text
http://192.168.5.22:3000
```

验证：

- 能打开登录页
- 使用 `.env` 中账号密码可登录
- Connections / Data sources 中 `Prometheus` datasource 正常
- datasource URL 为 `http://prometheus:9090`

### 4. 反代与域名访问

推荐正式入口：

```text
grafana.tools.home -> lxc-nginx-01 -> http://192.168.5.22:3000
```

如果反代尚未完成，可临时使用：

```text
grafana.tools.home -> 192.168.5.22
http://grafana.tools.home:3000
```

正式验收前必须确认最终入口可用：

```text
http://grafana.tools.home
```

### 5. 重启恢复

```bash
sudo reboot
```

LXC 恢复后执行：

```bash
cd /opt/homelab-platform/services/monitoring
docker compose ps
docker compose exec prometheus promtool query instant http://localhost:9090 up
```

预期：Prometheus 和 Grafana 自动恢复。

### 6. 备份覆盖确认

确认以下 Docker volumes 在 LXC 备份范围内：

```bash
docker volume ls | grep monitoring
docker volume inspect monitoring_prometheus_data monitoring_grafana_data
```

必须确认：

- `prometheus_data` 存储 Prometheus TSDB，保留 15 天。
- `grafana_data` 存储 Grafana 数据库、插件、本地状态。
- PVE/LXC 备份覆盖 Docker volume 数据目录。

## 回滚步骤

### 快速停服

```bash
cd /opt/homelab-platform/services/monitoring
docker compose down
```

### 配置回滚

```bash
git status
git switch main
git pull --ff-only
```

如需彻底回滚，使用 PVE 快照：

```text
pre-monitoring-v1
```

### 数据回滚

如果 Grafana 或 Prometheus 数据异常，恢复：

- `monitoring_prometheus_data`
- `monitoring_grafana_data`

恢复后重新执行验证步骤。

## 上线记录模板

上线完成后，在 PR 或运维记录中补充：

```markdown
## HomeLab Validation

- Date:
- Operator:
- Host: lxc-monitor-01 / 192.168.5.22
- Git commit:
- Snapshot: pre-monitoring-v1
- Compose config: pass/fail
- Prometheus self-scrape: pass/fail
- Node exporter targets: pass/fail, list down targets if any
- Grafana datasource: pass/fail
- Domain/reverse proxy: pass/fail
- Reboot recovery: pass/fail
- Backup coverage: pass/fail
- Issues:
- Follow-ups:
```

如执行了恢复演练，同时记录到 `docs/05-runbooks/backup-restore-drill.md`。

## PR 完成条件

全部 HomeLab 验证通过后：

1. 更新 PR 描述中的验证结果。
2. 将 PR 从 Draft 标记为 Ready for review。
3. 再执行最终合并。
