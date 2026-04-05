#!/bin/bash
# subagent-aggregate.sh — Subagent 结果聚合 Hook
# 事件: SubagentStop（子代理结束时）
# 功能: 收集 subagent 输出、评估置信度、触发后续处理
#
# 输出格式 (JSON):
#   {"continue": false, "reason": "..."} — 阻止停止，继续执行
#   {"continue": true} — 允许停止

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT_JSON=$(cat)
SESSION_ID=$(echo "$INPUT_JSON" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/' || echo "unknown")

PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
AGGREGATE_LOG="$PROJECT_DIR/.agentsspaces/aggregation.log"

# 确保目录存在
mkdir -p "$(dirname "$AGGREGATE_LOG")"

# 记录 subagent 完成
echo "$(date '+%Y-%m-%d %H:%M:%S') [subagent-stop] session=$SESSION_ID" >> "$AGGREGATE_LOG" || true

# 默认允许停止
echo '{"continue": true}'
exit 0
