---
name: hooks-index
version: 2.1
description: |
  Hook 事件驱动机制，基于 CodeBuddy 工具生命周期实现细粒度条件触发。
  采用退出码协议控制流程走向，结合声明式规则实现自动化。
---

# Hooks 索引（v2.0）

条件触发的命令脚本归档目录。

## 事件类型

参考 CodeBuddy 工具生命周期，定义以下事件：

| 事件 | 触发时机 | 说明 |
|------|----------|------|
| `SessionStart` | 会话开始 | 加载上下文、初始化环境 |
| `UserPromptSubmit` | 用户提交消息时 | 意图预判、智能体推荐 |
| `PreToolUse` | 工具调用前 | 参数校验、权限检查、安全拦截 |
| `PostToolUse` | 工具调用后 | 结果校验、副作用检测 |
| `Stop` | 会话结束时 | 日志压缩、评分、清理 |
| `SubagentStop` | 子代理结束时 | 结果聚合、置信度评估 |
| `PreCompact` | 上下文压缩前 | 保留关键信息 |
| `SessionEnd` | 会话结束时 | 保存状态、持久化环境变量 |
| `ArchitectureChange` | 架构变更请求时 | 强制架构审核 |

## 退出码协议

所有 Hook 脚本必须遵守以下退出码语义：

| 退出码 | 含义 | 行为 |
|--------|------|------|
| `0` | 放行 | 允许操作继续 |
| `1` | 警告 | 显示警告信息给用户，**不阻止**操作继续 |
| `2` | 阻止 | 阻止当前操作，通知 AI 修正后重试 |

## Hook 注册表

### 会话管理类

| Hook 名称 | 事件 | 执行脚本 | 用途 | 状态 |
|-----------|------|----------|------|------|
| session-init | `SessionStart` | `hooks/session-init.sh` | 加载上下文、检查环境完整性 | 已建设 |
| intent-classify | `UserPromptSubmit` | `hooks/intent-classify.sh` | 预判用户意图，推荐智能体 | 待建设 |
| session-end | `Stop` | `hooks/session-end.sh` | 触发日志压缩、会话评分 | 待建设 |
| session-state | `SessionEnd` | `hooks/session-state.sh` | 保存会话状态、持久化环境变量 | 已建设 |
| subagent-aggregate | `SubagentStop` | `hooks/subagent-aggregate.sh` | 结果聚合、置信度评估 | 已建设 |
| pre-compact | `PreCompact` | `hooks/pre-compact.sh` | 压缩前保留关键决策和信息 | 已建设 |

### 安全监控类

| Hook 名称 | 事件 | 执行脚本 | 用途 | 状态 |
|-----------|------|----------|------|------|
| security-check | `PreToolUse` | `hooks/security-check.sh` | 检测安全风险模式，高风险返回退出码 2 | 已建设 |
| command-validate | `PreToolUse` | `hooks/command-validate.sh` | 校验命令参数，防止误操作 | 待建设 |
| post-write-verify | `PostToolUse` | `hooks/post-write-verify.sh` | 文件写入后检查副作用 | 待建设 |

### 架构管控类

| Hook 名称 | 事件 | 执行脚本 | 用途 | 状态 |
|-----------|------|----------|------|------|
| architect-review | `ArchitectureChange` | `hooks/architect-review.sh` | 强制调用架构师智能体审核 | 待建设 |
| arch-changelog | `PostToolUse` | `hooks/arch-changelog.sh` | 架构变更后自动记录变更日志 | 待建设 |

### Ralph Loop 类

| Hook 名称 | 事件 | 执行脚本 | 用途 | 状态 |
|-----------|------|----------|------|------|
| ralph-loop-stop | `Stop` | `hooks/ralph-loop-stop.sh` | 阻止停止，自引用循环 | 已建设 |

## 安全监控规则

`security-check` Hook 检测以下 9 种安全模式：

| 模式 | 风险等级 | 检测内容 | 退出码 |
|------|----------|----------|--------|
| 命令注入 | 高 | `os.system(user_input)`、shell 拼接用户输入 | 2 |
| XSS | 高 | 未转义的 HTML 输出、`innerHTML` 赋值用户数据 | 2 |
| eval 使用 | 高 | `eval()`、`exec()` 执行动态代码 | 2 |
| 危险 HTML | 中 | `dangerouslySetInnerHTML`、未过滤的 HTML | 1 |
| pickle 反序列化 | 高 | `pickle.loads()` 处理不可信数据 | 2 |
| 硬编码密钥 | 高 | 明文密码、API Key、Token 写入代码 | 2 |
| SQL 注入 | 高 | 字符串拼接 SQL、未参数化查询 | 2 |
| 路径遍历 | 中 | 未校验的 `../` 路径拼接 | 1 |
| 不安全下载 | 中 | 无校验的 `requests.get` + 文件写入 | 1 |

## Hook 流程规范

```
1. 事件触发
   ↓
2. 匹配已注册的 Hook
   ↓
3. 执行 Hook 脚本
   ↓
4. 检查退出码
   ├─ 0 → 放行，继续执行
   ├─ 1 → 记录警告，继续执行
   └─ 2 → 阻止执行，通知 AI
   ↓
5. 记录执行结果到 progress.md
```

## 命名规范
`hooks/<event>-<action>.sh` 或 `hooks/<event>-<action>.py`
