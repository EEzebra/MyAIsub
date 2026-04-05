#!/bin/bash
# session-init.sh — 会话初始化 Hook
# 事件: SessionStart（会话开始时）
# 功能: 加载项目上下文、初始化环境变量、恢复会话状态
#
# 输出:
#   stdout 会被添加到 CodeBuddy 上下文中
#   退出码 0 表示成功

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT_JSON=$(cat)
SESSION_ID=$(echo "$INPUT_JSON" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
SOURCE=$(echo "$INPUT_JSON" | grep -o '"source"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"

# 会话状态文件
SESSION_ENV_FILE="$PROJECT_DIR/.claude/session.env"
PROJECT_CONTEXT_FILE="$PROJECT_DIR/docs/entry/PROJECT.md"

# 输出上下文内容
echo "## Session Context"
echo ""
echo "**Session ID**: ${SESSION_ID:-unknown}"
echo "**Source**: ${SOURCE:-startup}"
echo "**Project**: $(basename "$PROJECT_DIR")"
echo ""

# 1. 加载项目上下文
if [ -f "$PROJECT_CONTEXT_FILE" ]; then
    echo "### Project Context"
    head -50 "$PROJECT_CONTEXT_FILE"
    echo ""
fi

# 2. 加载会话环境变量
if [ -f "$SESSION_ENV_FILE" ]; then
    echo "### Session Environment"
    # 读取并显示已保存的环境变量
    grep -v '^#' "$SESSION_ENV_FILE" 2>/dev/null | while read -r line; do
        if [ -n "$line" ]; then
            echo "- $line"
        fi
    done
    echo ""
fi

# 3. 检查是否有未完成的任务
TASK_PLAN="$PROJECT_DIR/docs/subagent-integration/task_plan.md"
if [ -f "$TASK_PLAN" ]; then
    CURRENT_PHASE=$(grep -A1 "## Current Phase" "$TASK_PLAN" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')
    if [ -n "$CURRENT_PHASE" ]; then
        echo "### Active Task"
        echo "**Current Phase**: $CURRENT_PHASE"
        echo "See: docs/subagent-integration/task_plan.md"
        echo ""
    fi
fi

# 4. 提供 agent 协作指引
echo "### Available Agents"
echo "| Agent | Codename | Role |"
echo "|-------|----------|------|"
echo "| planner | 魔术师 | 任务指挥中枢 |"
echo "| coder | 战车 | 代码执行引擎 |"
echo "| tester | 正义 | 质量守卫者 |"
echo "| architect | 皇帝 | 核心守门人 |"
echo "| maintainer | 星星 | 用户体验引擎 |"
echo "| coordinator | 教皇 | 并行协调器 |"
echo ""

exit 0
