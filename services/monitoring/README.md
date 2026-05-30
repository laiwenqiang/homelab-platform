# Monitoring (Prometheus + Grafana)

## 目标

在 `lxc-monitor-01` 上运行 Prometheus + Grafana，作为 HomeLab 的基础可观测入口。

- Host：`lxc-monitor-01`
- IP：`192.168.5.22`
- Zone：`tools`
- URL：`grafana.tools.home`
- Deploy：Docker Compose

## 部署

正式上线按 `docs/05-runbooks/monitoring-deploy.md` 执行；以下为服务目录内的快速步骤。

1. 在 `lxc-monitor-01` 完成基线初始化并安装 Docker / Docker Compose。
2. 进入本目录：
   - `cd services/monitoring`
3. 设置 Grafana 初始管理员密码：
   - 在本地 `.env` 中设置 `GF_SECURITY_ADMIN_PASSWORD`，不要提交到 Git。
   - 可选：设置 `GF_SECURITY_ADMIN_USER`，默认值为 `admin`。
4. 启动服务：
   - `docker compose up -d`
5. 接入反代：
   - `grafana.tools.home -> http://192.168.5.22:3000`

## 验证

- `docker compose ps`
- `docker compose logs --tail=100 prometheus grafana`
- `docker compose exec prometheus promtool check config /etc/prometheus/prometheus.yml`
- `docker compose exec prometheus promtool query instant http://localhost:9090 up`
- 访问 `http://192.168.5.22:3000` 或 `http://grafana.tools.home`
- 在 Grafana 中确认 `Prometheus` datasource 正常。

## 配置与状态

Git 管理：

- `docker-compose.yml`
- `prometheus/prometheus.yml`
- `grafana/provisioning/datasources/prometheus.yml`
- `grafana/provisioning/dashboards/dashboards.yml`
- `grafana/dashboards/`

Docker volume：

- `prometheus_data`：Prometheus TSDB，默认保留 15 天。
- `grafana_data`：Grafana 数据库、插件、本地状态。

Dashboard 约定：

- 未来新增 dashboard JSON 放入 `grafana/dashboards/`。
- Dashboard 以 Git 中的 JSON 为准，不建议长期只在 Grafana UI 中手工维护。

## 备份

- 纳入 `lxc-monitor-01` 的 PVE/LXC 备份策略。
- 重点确认 `prometheus_data` 与 `grafana_data` 两个 Docker volume 可恢复。
- 每月恢复演练记录到 `docs/05-runbooks/backup-restore-drill.md`。

## 回滚

1. 上线前创建 LXC 快照：`pre-monitoring-v1`。
2. 如服务异常：
   - `docker compose down`
   - 恢复到上一个 Git revision 或 LXC 快照。
3. 如数据异常：恢复 `prometheus_data` / `grafana_data` volume 备份。

## 暂不包含

- Node Exporter / cAdvisor
- Loki
- Alertmanager / 通知渠道
- 多主机 scrape target
