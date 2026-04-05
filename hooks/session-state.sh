#!/bin/bash
# session-state.sh — 会话状态管理 Hook
# 事件: SessionEnd（会话结束时）
# 功能: 保存会话状态、环境变量持久化、生成会话摘要
#
# 输出:
#   stdout 记录到日志

set -euo pipefail

# 从 stdin 读取 JSON 输入
INPUT_JSON=$(cat)
SESSION_ID=$(echo "$INPUT_JSON" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
REASON=$(echo "$INPUT_JSON" | grep -o '"reason"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
TRANSCRIPT_PATH=$(echo "$INPUT_JSON" | grep -o '"transcript_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')

PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
SESSION_ENV_FILE="$PROJECT_DIR/.claude/session.env"
SESSION_LOG="$PROJECT_DIR/.agentsspaces/sessions"

# 确保目录存在
mkdir -p "$(dirname "$SESSION_ENV_FILE")"
mkdir -p "$SESSION_LOG"

# 1. 保存会话摘要
SUMMARY_FILE="$SESSION_LOG/session-$(date +%Y-%m-%d-%H%M%S).md"
{
    echo "# Session Summary"
    echo ""
    echo "**Session ID**: ${SESSION_ID:-unknown}"
    echo "**End Time**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**End Reason**: ${REASON:-other}"
    echo ""
    echo "## Key Files Modified"
    echo "See transcript for details: ${TRANSCRIPT_PATH:-N/A}"
} > "$SUMMARY_FILE"

# 2. 生成环境变量持久化建议
if [ -f "$PROJECT_DIR/docs/subagent-integration/progress.md" ]; then
    # 从 progress.md 提取关键决策
    DECISIONS=$(grep -A5 "## Decisions Made" "$PROJECT_DIR/docs/subagent-integration/progress.md" 2>/dev/null | head -10)
    if [ -n "$DECISIONS" ]; then
        echo "# Session Environment Variables" > "$SESSION_ENV_FILE"
        echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$SESSION_ENV_FILE"
        echo "# Persist key decisions across sessions" >> "$SESSION_ENV_FILE"
        echo "" >> "$SESSION_ENV_FILE"
        echo "# Example: export LAST_PHASE=\"Stage 1\"" >> "$SESSION_ENV_FILE"
    fi
fi

echo "[SessionEnd] Saved session summary to $SUMMARY_FILE"
exit 0
