# 项目记忆

记录重要决策、进度和待办事项。

---

## 已完成任务

### 2026-04-06: HOOK 自动触发机制建设

**状态**: ✅ 已完成

**完成内容**:

| Hook | 事件 | 功能 | 状态 |
|------|------|------|------|
| intent-classify.sh | UserPromptSubmit | 意图识别，推荐智能体 | ✅ |
| arch-changelog.sh | PostToolUse | 架构变更检测，敏感文件触发审核 | ✅ |
| architect-review.sh | PostToolUse (内部调用) | 强制架构审核 | ✅ |
| session-end.sh | Stop | 日志压缩、会话评分 | ✅ |

**配置文件**: `.claude/settings.json`

**退出码协议**:
- 0: 放行
- 1: 警告（不阻止）
- 2: 阻止（需修正后重试）

**敏感文件模式**:
- `agents/*/AGENT.md` - Agent 定义
- `hooks/*.sh` - Hook 脚本
- `docs/architecture/*` - 架构文档
- `CLAUDE.md`, `MEMORY.md` - 项目配置
- `.claude/settings.json` - 配置文件

**测试验证**: Tester（正义）验证通过，置信度 90%

---

## 待办任务

*暂无*

---

## 项目结构

```
agents/
├── planner/      # 魔术师 - 任务指挥中枢
├── coder/        # 战车 - 代码执行引擎
├── tester/       # 正义 - 质量守卫者
├── architect/    # 皇帝 - 核心守门人
├── maintainer/   # 星星 - 用户体验引擎
└── coordinator/  # 教皇 - 并行协调器

hooks/
├── INDEX.md           # Hook 索引
├── session-init.sh    # 会话初始化
├── intent-classify.sh # 意图识别
├── security-check.sh  # 安全检查
├── arch-changelog.sh  # 架构变更日志
├── architect-review.sh# 架构审核
├── session-end.sh     # 会话结束
├── session-state.sh   # 状态持久化
├── subagent-aggregate.sh # 子代理聚合
└── pre-compact.sh     # 压缩前处理

.claude/
├── settings.json      # Hooks 配置
├── logs/              # 日志目录
└── stats/             # 统计目录
```
