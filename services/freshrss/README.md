# FreshRSS (docker-compose)

## 部署
1. 复制环境变量：
   - `cp .env.example .env`
   - 修改密码等敏感项
2. 启动：
   - `docker compose up -d`
3. 访问：
   - http://<host>:8080
4. 接入反代：
   - freshrss.tools.home -> http://<host>:8080

## 备份建议
- volumes：db_data、freshrss_data、freshrss_extensions
- 频率：每周全量 + 月度恢复演练
