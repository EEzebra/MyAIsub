# 架构变更日志

记录 MyAI 项目的架构变更历史。

| 日期 | 风险等级 | 变更描述 | 影响范围 | 决策者 |
|------|----------|----------|----------|--------|
| 2026-04-06 | 高 | commons/ 重命名为 commands/ | 目录结构、引用文件 | user |
| 2026-04-06 | 中 | 补齐所有 Agent 的 rules.md | agents/* | architect |
| 2026-04-06 | 中 | 新增 arch-health-check.sh 架构检查命令 | commands/ | architect |
| 2026-04-06 | 中 | 扩展 setup.sh 初始化能力 | docs/entry/ | architect |
| 2026-04-06 | 低 | 新增 .claude 目录初始化逻辑 | .claude/ | architect |

---

## 变更详情

### 2026-04-06: commons 重命名为 commands

**原因**: 原命名 commons 为误写，正确意图为 commands（命令集）

**影响文件**:
- `commons/` → `commands/`
- `rules/project-rules.md`
- `README.md`
- `docs/entry/setup.sh`

### 2026-04-06: 补齐 Agent rules.md

**原因**: 架构师（皇帝）未遵守自己定义的规范，导致部分 Agent 缺少 rules.md

**新增文件**:
- `agents/planner/rules.md`
- `agents/coder/rules.md`
- `agents/architect/rules.md`
- `agents/coordinator/rules.md`

### 2026-04-06: 架构健康检查机制

**原因**: 架构规范缺少自动化检查机制，导致规范被破坏

**新增文件**:
- `commands/arch-health-check.sh`

**功能**:
- Agent 目录结构完整性检查
- 核心目录和文件检查
- 命名规范检查
- .claude 目录检查
- 变更日志检查

### 2026-04-06: setup.sh 能力扩展

**原因**: 原 setup.sh 缺少关键初始化能力

**新增功能**:
- Agent rules.md 完整性检查
- .claude 目录初始化
- commands 脚本权限配置
- 架构健康检查调用
