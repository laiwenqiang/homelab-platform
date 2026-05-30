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

本次不包含：Node Exporter、cAdvisor、Loki、Alertmanager、多主机 scrape target。

## PR 门禁

Monitor PR 必须保持 Draft，直到以下条件全部完成：

- [ ] 在真实 `lxc-monitor-01` 上完成部署。
- [ ] `docker compose config` 通过。
- [ ] Prometheus self-scrape 正常。
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

### 3. 校验 Compose 配置

```bash
docker compose config
```

失败时不要启动服务，先修正配置或回滚。

### 4. 启动服务

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
docker compose exec prometheus promtool query instant http://localhost:9090 up
```

预期：`up` 查询返回 Prometheus self-scrape 目标，值为 `1`。

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
