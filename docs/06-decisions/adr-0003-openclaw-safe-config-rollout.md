# ADR-0003: OpenClaw 配置变更采用安全发布、自动回退与定时健康检查

- Status: Proposed
- Date: 2026-03-08

## Context
OpenClaw 运行在 homelab 的 AI 隔离 VM 中，属于高风险且对可用性敏感的服务。

2026-03-06 曾发生一次严重故障：由于配置中写入了无效 provider API 类型，Gateway 在重启后进入长时间不可用和重复重启状态，持续约 6 小时 53 分钟，期间累计重启 565+ 次。事故暴露出以下问题：

- 配置变更缺少发布前校验
- 使用 `openclaw gateway restart` 后未验证服务是否真正恢复
- 缺少 `last-known-good` 配置与自动回退机制
- 缺少定时健康检查，故障无法被快速发现和自愈
- 模型 fallback 等配置需要严格使用 OpenClaw 官方支持的字段与语义，否则重启阶段可能触发配置无效或运行异常

在当前运行环境中，OpenClaw 由 systemd 用户服务托管，因此具备做“配置发布脚本 + 健康检查 + 自动回退”的基础条件。

## Decision
对 OpenClaw 的配置变更采用“安全发布（safe rollout）”策略，具体如下：

1. **配置变更前强制备份**
   - 正式配置文件：`~/.openclaw/openclaw.json`
   - 时间戳备份：`~/.openclaw/backups/openclaw.json.<timestamp>`
   - 最后已知可用配置：`~/.openclaw/openclaw.json.last-known-good`

2. **只使用 OpenClaw 官方支持字段**
   - 模型降级使用 `agents.defaults.model.fallbacks`
   - 不允许使用未文档化或错误语义字段（如 `fallback` 单字段）直接上线

3. **配置修改后先校验、再重启**
   - 通过脚本调用官方命令进行校验与状态检查
   - 校验不通过则中止，不执行重启
   - 校验通过后，才调用受支持的重启路径

4. **重启后做健康验证**
   - 检查 systemd 服务状态
   - 检查 `openclaw status` / 可用 health 命令
   - 必要时检查最近日志，确认服务不是“进程活着但功能异常”

5. **异常时自动回退**
   - 若重启后检查失败，则自动恢复 `last-known-good`
   - 回退后再次重启并验证
   - 记录回退事件与日志位置

6. **增加定时健康检查**
   - 定时检查 OpenClaw 服务状态与应用状态
   - 当发现异常达到阈值时，自动触发回退逻辑
   - 保留日志与事件记录，便于审计和复盘

7. **保留人工接管路径**
   - 自动回退失败时，允许按 runbook 手工恢复
   - 生产变更前，始终保留最近可用配置和手工回退步骤

## Consequences
### 收益
- 降低配置错误直接打挂 OpenClaw 的概率
- 降低“重启后长期不可用却无人发现”的风险
- 配置变更具备可回退、可审计、可演练特性
- 将 OpenClaw 从“手工维护服务”提升为“具备基本自愈能力的关键基础设施”

### 代价 / 风险
- 增加脚本、timer、runbook 的维护成本
- 健康检查若设计不当，可能误判并触发不必要回退
- `last-known-good` 若更新时机不对，可能保存了逻辑上有问题的配置
- 需要明确官方命令边界：哪些用于校验，哪些用于重启，避免再次踩到不可靠路径

## Alternatives considered
### 1. 继续手工编辑配置 + 手工重启
不采用。原因：已经被事故证明风险过高，且依赖人工记忆做校验与检查。

### 2. 只做模型 fallback，不做服务级回退
不采用。原因：模型 fallback 只能处理 provider/model 层故障，无法解决配置无效、服务启动失败、systemd 重启循环等问题。

### 3. 引入更复杂的编排系统（如容器平台/K8s operator）
暂不采用。原因：当前 homelab 里 OpenClaw 部署在独立 VM，优先用 systemd + 脚本实现简单可靠方案，复杂度更低，收益更直接。

## Rollback plan
- 若该机制本身引发异常：
  1. 停用定时健康检查/自动回退任务
  2. 恢复到最近确认可用的 `openclaw.json.last-known-good`
  3. 使用 runbook 中的人工步骤重启并验证 OpenClaw
  4. 保留现场日志，重新评估健康检查阈值与脚本逻辑
