# Findings & Decisions

## Requirements
- 多轮 LLM 对话功能：会话状态持久化、上下文压缩策略
- 多 Agent 协作机制：并行执行、结果聚合、协调调度
- 与现有 MyAIsub 架构兼容：不破坏现有 5 个 Agent 的协作链路

## Research Findings

### claude-code 项目发现

**多轮对话实现方式：**
```
SessionStart Hook → 注入上下文
     ↓
Ralph Loop → 自引用循环（同prompt反复执行）
     ↓
PreCompact Hook → 压缩前保留关键信息
     ↓
$CLAUDE_ENV_FILE → 环境变量持久化
```

**并行 Agent 执行模式：**
```markdown
# feature-dev 命令示例
1. Launch 2-3 code-explorer agents in parallel
2. Each agent targets different aspect
3. Results aggregated by main agent
```

**Agent 定义标准（YAML Frontmatter）：**
```yaml
---
name: agent-name
description: |
  功能描述，包含触发示例 <example> 块
model: inherit | sonnet | opus | haiku
color: <color>
tools: [tool1, tool2]
---
```

### MyAIsub 现状发现

**现有架构：**
- 5 个 Agent：planner, coder, tester, architect, maintainer
- 协作链路：planner → coder → architect → tester → maintainer
- Hooks：6 种事件（SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, ArchitectureChange）
- Skills：19 个技能，集中式管理

**差距：**
- 缺少 PreCompact、SessionEnd、SubagentStop 事件
- 缺少环境变量持久化机制
- 缺少并行 Agent 执行模式
- 缺少结果聚合机制

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 使用 planning-with-files 进行任务跟踪 | 符合 MyAIsub 已有的 docs/ 管理模式 |
| 在 docs/subagent-integration/ 下创建规划文件 | 独立目录，不影响现有结构 |
| 优先移植 SessionStart Hook | 最小改动，最大收益 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
|       |            |

## Resources
- `/home/workspace/AIPro1/claude-code/plugins/ralph-wiggum/` - Ralph Loop 实现
- `/home/workspace/AIPro1/claude-code/plugins/feature-dev/agents/` - 并行 Agent 示例
- `/home/workspace/AIPro1/claude-code/plugins/explanatory-output-style/hooks/` - SessionStart Hook 示例
- `/home/workspace/AIPro1/MyAIsub/hooks/INDEX.md` - 现有 Hooks 定义

## Visual/Browser Findings
- N/A

---
*Update this file after every 2 view/browser/search operations*
