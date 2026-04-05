# 架构变更日志

记录所有 MyAI 架构变更，无论风险等级。

## 格式
```
[日期] [风险等级] [变更描述] [影响范围] [决策者] [审核者]
```

## 变更记录

### 2026-04-05
| 风险等级 | 变更描述 | 影响范围 | 决策者 | 审核者 |
|----------|----------|----------|--------|--------|
| 中高风险 | SubAgent 功能整合项目启动（方案 C） | 全局 | 用户 + architect | architect |
| 低风险 | 新增 SessionStart Hook（session-init.sh） | hooks/ | 用户 + planner | tester |
| 低风险 | 新增 SessionEnd Hook（session-state.sh） | hooks/ | 用户 + planner | tester |
| 低风险 | 新增 SubagentStop Hook（subagent-aggregate.sh） | hooks/ | 用户 + planner | tester |
| 中风险 | 新增 coordinator Agent（教皇） | agents/ | 用户确认 | architect |
| 低风险 | 扩展 Hooks 索引（新增 3 种事件类型） | hooks/INDEX.md | 用户 + planner | tester |
| 中风险 | 移植 Ralph Loop（命令 + 脚本 + Stop Hook） | .claude/, hooks/ | 用户 + planner | tester |
| 低风险 | 新增 PreCompact Hook（对话压缩前保留信息） | hooks/ | 用户 + planner | tester |
| 低风险 | 新增 tester 规则文件（测试决策流程 + 动态测试规范） | agents/tester/ | 用户 | — |
| 低风险 | 修复 ralph-loop-stop.sh 使用 CODEBUDDY_PROJECT_DIR | hooks/ | 用户 | — |

### 2026-04-03
| 风险等级 | 变更描述 | 影响范围 | 决策者 | 审核者 |
|----------|----------|----------|--------|--------|
| 低风险 | 创建初始项目骨架（8 目录 + 文件） | 全局 | 用户 + planner | — |
| 低风险 | 升级 AGENT.md 增加 YAML Frontmatter | agents/ | 用户 + planner | — |
| 低风险 | 升级 hooks 体系为事件驱动 + 退出码协议 | hooks/ | 用户 + planner | — |
| 低风险 | 新增安全监控 Hook（security-check.sh） | hooks/ | 用户 + planner | — |
| 低风险 | 新增 feature-dev 场景流程（7 阶段） | spec/ | 用户 + planner | — |
| 低风险 | 新增 architect 多方案设计能力 | agents/architect/ | 用户 + planner | — |
| 低风险 | 新增 tester 并行验证 + 置信度过滤 | agents/tester/ | 用户 + planner | — |
| 低风险 | 新增 maintainer 5 维度评分体系 | agents/maintainer/ | 用户 + planner | — |
