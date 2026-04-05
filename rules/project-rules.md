# 项目规则

MyAI 项目开发中必须遵守的规则。

## 1. 目录规范
| 目录 | 用途 | 约束 |
|------|------|------|
| `agents/` | 智能体定义 | 每个智能体一个子目录，包含 AGENT.md 和 rules.md |
| `commons/` | 命令集 | 按功能分类存放，需在 INDEX.md 中注册 |
| `docs/` | 知识库 | 所有文档和知识记录的集中存储 |
| `hooks/` | 条件脚本 | 按事件类型分类，遵守退出码协议 |
| `rules/` | 规则 | AI 规则和项目规则分开存放 |
| `skills/` | 技能 | 每个技能一个子目录，遵循 skill-creator 规范 |
| `spec/` | 场景流程 | 按场景分类，定义清晰的阶段和确认门 |

## 2. 文件命名约定
| 类型 | 命名格式 | 示例 |
|------|----------|------|
| 智能体定义 | `AGENT.md`（大写） | `agents/planner/AGENT.md` |
| 智能体规则 | `rules.md` | `agents/planner/rules.md` |
| 命令脚本 | `kebab-case.sh` 或 `.py` | `commons/init-env.sh` |
| 规则文件 | `kebab-case.md` | `rules/ai-rules.md` |
| 知识文档 | `kebab-case.md` | `docs/findings.md` |
| 场景流程 | `kebab-case.md` | `spec/feature-dev.md` |
| Hook 脚本 | `<event>-<action>.sh` | `hooks/security-check.sh` |
| 变更日志 | `kebab-case.md` | `docs/arch-changelog.md` |

## 3. Agent Frontmatter 标准

所有 AGENT.md 必须包含 YAML frontmatter：

```yaml
---
name: <agent-name>
codename: <塔罗牌代号>    # 可选，如：魔术师、战车、正义、皇帝、星星
description: |
  Agent 功能描述，包含触发示例 <example> 块
model: inherit          # inherit / sonnet / opus / haiku
color: <color>          # UI 视觉标识
tools: [tool1, tool2]   # 可用工具列表（最小权限原则）
---
```

**必须包含的字段**：name, description, model, color, tools
**description 中必须包含**：`<example>` 触发示例块

## 4. Hook 退出码协议

| 退出码 | 含义 | 行为 |
|--------|------|------|
| 0 | 放行 | 允许操作继续 |
| 1 | 警告 | 显示警告，不阻止 |
| 2 | 阻止 | 阻止操作，通知 AI 修正 |

## 5. 规则优先级
```
全局规则（rules/）> 项目规则 > 场景规则（spec/）> 临时规则
```

## 6. 智能体协作规则
- 所有任务由计划智能体（planner）统一调度
- 编码智能体（coder）修改架构前必须调用架构师智能体（architect）
- 测试智能体（tester）发现问题反馈给编码智能体（coder），修复后回归验证
- 项目维护智能体（maintainer）在会话结束时触发评分
- 可并行的子任务必须同时执行

## 7. CodeBuddy 工具映射

| 工具 | 用途 | 主要使用智能体 |
|------|------|---------------|
| read_file | 读取文件 | 所有 |
| write_to_file / replace_in_file | 文件操作 | coder |
| list_files / search_file / search_content | 代码搜索 | tester, code-explorer |
| read_lints | Linter 检查 | coder, tester |
| execute_command | 执行命令 | coder, tester |
| task | 并行 subagent | planner, tester |
| use_skill | 调用技能 | coder, planner |
| update_memory | 持久化记忆 | maintainer |
| create_rule | 创建规则 | planner |

## 8. 文档规范
- 所有规划文件存放在 `docs/` 知识库中
- 使用 Markdown 格式
- 重要信息使用表格记录
- 变更记录需包含时间戳
- AGENT.md 支持 YAML Frontmatter
