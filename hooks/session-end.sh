#!/bin/bash
# session-end.sh — 会话结束 Hook
# 事件: Stop（会话结束时）
# 功能: 基础统计、日志压缩、数据记录
#
# ⚠️ 限制说明:
#   此脚本只能执行 Shell 能做的操作：
#   - 统计 git 文件变更
#   - 压缩旧日志
#   - 写入基础统计数据
#
#   以下操作需要 AI 能力，此脚本无法执行：
#   - 偏好提取（需要语义理解）
#   - 5 维度评分（需要多维度分析）
#   - 规则提取（需要模式识别）
#
#   如需 AI 分析功能，请手动调用 maintainer 智能体。
#
# 输入:
#   stdin - JSON 格式的会话信息（可选）
# 输出:
#   stdout - 会话基础统计
# 退出码:
#   0 — 成功

set -euo pipefail

# --- 配置 ---
PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
SESSION_DIR="$PROJECT_DIR/.claude"
LOG_DIR="$SESSION_DIR/logs"
STATS_DIR="$SESSION_DIR/stats"
PREFS_DIR="$SESSION_DIR/preferences"
DOCS_LOGS_DIR="$PROJECT_DIR/docs/logs"

mkdir -p "$LOG_DIR" "$STATS_DIR" "$PREFS_DIR" "$DOCS_LOGS_DIR"

# 从 stdin 读取会话信息（可选）
INPUT_JSON=$(cat 2>/dev/null || echo "{}")

# --- 基础数据收集 ---
collect_basic_stats() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local date_only=$(date '+%Y-%m-%d')
    local session_id="${date_only}-$$"

    # 统计本次会话的 git 变更
    local files_modified=0

    if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
        # 获取未提交的变更
        local git_status=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || echo "")
        files_modified=$(echo "$git_status" | grep -c . 2>/dev/null || echo "0")
    fi

    # 统计工具调用次数（从 intent-classify.log）
    local tool_calls=0
    if [ -f "$LOG_DIR/intent-classify.log" ]; then
        tool_calls=$(wc -l < "$LOG_DIR/intent-classify.log" 2>/dev/null || echo "0")
    fi

    # 检查错误日志
    local error_count=0
    error_count=$(find "$LOG_DIR" -name "*.log" -exec grep -l -i "error\|failed" {} \; 2>/dev/null | wc -l || echo "0")

    # 输出 JSON 格式的统计数据
    cat <<EOF
{
    "timestamp": "$timestamp",
    "session_id": "$session_id",
    "date": "$date_only",
    "files_modified": $files_modified,
    "tool_calls": $tool_calls,
    "error_count": $error_count
}
EOF
}

# --- 日志压缩 ---
compress_logs() {
    local log_archive="$LOG_DIR/archive"
    mkdir -p "$log_archive"

    # 压缩 7 天前的日志
    find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \; 2>/dev/null || true
    find "$LOG_DIR" -name "*.log.gz" -exec mv {} "$log_archive/" \; 2>/dev/null || true

    # 删除 30 天前的压缩日志
    find "$log_archive" -name "*.gz" -mtime +30 -delete 2>/dev/null || true
}

# --- 基础活动指数（非 AI 评分）---
calculate_activity_index() {
    local files_modified=$1
    local tool_calls=$2
    local error_count=$3

    # 这是一个简单的活动指数，不是 maintainer 的 5 维度评分
    local index=50  # 基础分

    # 活动加分
    if [ "$files_modified" -gt 0 ]; then
        local file_score=$((files_modified * 5))
        if [ $file_score -gt 20 ]; then
            file_score=20
        fi
        index=$((index + file_score))
    fi

    if [ "$tool_calls" -gt 0 ]; then
        local tool_score=$((tool_calls * 2))
        if [ $tool_score -gt 15 ]; then
            tool_score=15
        fi
        index=$((index + tool_score))
    fi

    # 错误扣分
    if [ "$error_count" -gt 0 ]; then
        index=$((index - error_count * 10))
    fi

    # 确保在 0-100 范围内
    if [ $index -lt 0 ]; then
        index=0
    fi
    if [ $index -gt 100 ]; then
        index=100
    fi

    echo $index
}

# --- 写入会话日志 ---
write_session_log() {
    local stats_json=$1
    local activity_index=$2

    local date=$(echo "$stats_json" | grep -oP '"date"\s*:\s*"\K[^"]*' 2>/dev/null || date '+%Y-%m-%d')
    local session_id=$(echo "$stats_json" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
    local files_modified=$(echo "$stats_json" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
    local tool_calls=$(echo "$stats_json" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

    local log_file="$DOCS_LOGS_DIR/session-$date.md"

    # 如果文件已存在，追加内容
    if [ -f "$log_file" ]; then
        echo "" >> "$log_file"
        echo "---" >> "$log_file"
        echo "" >> "$log_file"
        echo "## 基础统计 ($session_id)" >> "$log_file"
        echo "" >> "$log_file"
    else
        cat > "$log_file" << 'HEREDOC'
# Session Log

此文件由 session-end.sh 自动生成。

注意：此日志只包含基础统计数据。如需 AI 分析（偏好提取、5 维度评分），
请手动调用 maintainer 智能体。

---

HEREDOC
        echo "**日期**: $date" >> "$log_file"
        echo "**会话 ID**: $session_id" >> "$log_file"
        echo "" >> "$log_file"
    fi

    echo "| 指标 | 数值 |" >> "$log_file"
    echo "|------|------|" >> "$log_file"
    echo "| 文件修改 | $files_modified |" >> "$log_file"
    echo "| 工具调用 | $tool_calls |" >> "$log_file"
    echo "| 活动指数 | $activity_index/100 |" >> "$log_file"
    echo "" >> "$log_file"
}

# --- 更新统计数据 ---
update_stats_csv() {
    local stats_json=$1
    local activity_index=$2

    local stats_file="$STATS_DIR/session_stats.csv"
    local timestamp=$(echo "$stats_json" | grep -oP '"timestamp"\s*:\s*"\K[^"]*' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')
    local session_id=$(echo "$stats_json" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
    local files_modified=$(echo "$stats_json" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
    local tool_calls=$(echo "$stats_json" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

    if [ ! -f "$stats_file" ]; then
        echo "timestamp,session_id,activity_index,files_modified,tool_calls" > "$stats_file"
    fi

    echo "$timestamp,$session_id,$activity_index,$files_modified,$tool_calls" >> "$stats_file"
}

# --- 初始化偏好文件（如果不存在）---
init_preferences_file() {
    local prefs_file="$PREFS_DIR/user-preferences.md"

    if [ ! -f "$prefs_file" ]; then
        cat > "$prefs_file" << 'HEREDOC'
# 用户偏好记录

此文件由 maintainer（星星）智能体手动触发时维护。
session-end.sh 只会创建此文件，不会更新内容。

---

## 工作风格偏好

| 偏好 | 权重 | 来源会话 | 备注 |
|------|------|---------|------|
| （待 maintainer 填充）| | | |

HEREDOC
    fi
}

# --- 执行主流程 ---
STATS_JSON=$(collect_basic_stats)

FILES_MODIFIED=$(echo "$STATS_JSON" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
TOOL_CALLS=$(echo "$STATS_JSON" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
ERROR_COUNT=$(echo "$STATS_JSON" | grep -oP '"error_count"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

ACTIVITY_INDEX=$(calculate_activity_index "$FILES_MODIFIED" "$TOOL_CALLS" "$ERROR_COUNT")

# 执行各项操作
compress_logs
write_session_log "$STATS_JSON" "$ACTIVITY_INDEX"
update_stats_csv "$STATS_JSON" "$ACTIVITY_INDEX"
init_preferences_file

# --- 输出会话总结 ---
SESSION_ID=$(echo "$STATS_JSON" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")

echo ""
echo "## 会话结束统计"
echo ""
echo "**Session ID**: ${SESSION_ID:0:16}..."
echo "**文件修改**: $FILES_MODIFIED 个"
echo "**工具调用**: $TOOL_CALLS 次"
echo "**活动指数**: $ACTIVITY_INDEX/100"
echo ""
echo "### 数据已保存"
echo ""
echo "- 会话日志: \`docs/logs/session-$(date '+%Y-%m-%d').md\`"
echo "- 统计数据: \`.claude/stats/session_stats.csv\`"
echo ""
echo "### AI 分析"
echo ""
echo "如需偏好提取、5 维度评分，请手动调用 maintainer 智能体："
echo "\`\`\`"
echo "用户: 总结一下这次对话"
echo "\`\`\`"
echo ""

exit 0
