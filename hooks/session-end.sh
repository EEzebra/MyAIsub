#!/bin/bash
# session-end.sh — 会话结束 Hook
# 事件: Stop（会话结束时）
# 功能: 收集会话数据、写入日志、更新偏好、计算评分
#
# 输入:
#   stdin - JSON 格式的会话信息（可选）
# 输出:
#   stdout - 会话总结和评分
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

# --- 真实数据收集 ---
collect_real_stats() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local date_only=$(date '+%Y-%m-%d')
    local session_id="${date_only}-$$"

    # 统计本次会话的 git 变更
    local files_modified=0
    local lines_added=0
    local lines_deleted=0

    if git -C "$PROJECT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
        # 获取未提交的变更
        local git_status=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null || echo "")
        files_modified=$(echo "$git_status" | grep -c . 2>/dev/null || echo "0")

        # 获取最近的提交统计
        local last_commit=$(git -C "$PROJECT_DIR" log -1 --format="%H" 2>/dev/null || echo "")
        if [ -n "$last_commit" ]; then
            local commit_stats=$(git -C "$PROJECT_DIR" show --stat --format="" "$last_commit" 2>/dev/null | tail -1)
            lines_added=$(echo "$commit_stats" | grep -oP '\d+(?= insertion)' 2>/dev/null || echo "0")
            lines_deleted=$(echo "$commit_stats" | grep -oP '\d+(?= deletion)' 2>/dev/null || echo "0")
        fi
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
    "lines_added": $lines_added,
    "lines_deleted": $lines_deleted,
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

# --- 会话评分计算 ---
calculate_score() {
    local files_modified=$1
    local tool_calls=$2
    local error_count=$3

    local score=50  # 基础分

    # 任务完成度加分（文件修改）
    if [ "$files_modified" -gt 0 ]; then
        local file_score=$((files_modified * 5))
        if [ $file_score -gt 20 ]; then
            file_score=20
        fi
        score=$((score + file_score))
    fi

    # 响应效率加分（工具调用）
    if [ "$tool_calls" -gt 0 ]; then
        local tool_score=$((tool_calls * 2))
        if [ $tool_score -gt 15 ]; then
            tool_score=15
        fi
        score=$((score + tool_score))
    fi

    # 错误扣分
    if [ "$error_count" -gt 0 ]; then
        score=$((score - error_count * 10))
    fi

    # 确保分数在 0-100 范围内
    if [ $score -lt 0 ]; then
        score=0
    fi
    if [ $score -gt 100 ]; then
        score=100
    fi

    echo $score
}

# --- 写入会话日志 ---
write_session_log() {
    local stats_json=$1
    local score=$2

    local date=$(echo "$stats_json" | grep -oP '"date"\s*:\s*"\K[^"]*' 2>/dev/null || date '+%Y-%m-%d')
    local session_id=$(echo "$stats_json" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
    local files_modified=$(echo "$stats_json" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
    local tool_calls=$(echo "$stats_json" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

    local log_file="$DOCS_LOGS_DIR/session-$date.md"

    # 如果文件已存在，追加内容；否则创建新文件
    if [ -f "$log_file" ]; then
        # 追加模式：只更新统计数据
        echo "" >> "$log_file"
        echo "---" >> "$log_file"
        echo "" >> "$log_file"
        echo "## 会话记录追加 ($session_id)" >> "$log_file"
        echo "" >> "$log_file"
    else
        # 创建新的会话日志
        cat > "$log_file" << 'HEREDOC'
# Session Log

此文件由 session-end.sh 自动生成和维护。

---

## 会话统计

HEREDOC
        echo "" >> "$log_file"
        echo "**日期**: $date" >> "$log_file"
        echo "**会话 ID**: $session_id" >> "$log_file"
        echo "" >> "$log_file"
    fi

    echo "### 统计数据" >> "$log_file"
    echo "" >> "$log_file"
    echo "| 指标 | 数值 |" >> "$log_file"
    echo "|------|------|" >> "$log_file"
    echo "| 文件修改 | $files_modified |" >> "$log_file"
    echo "| 工具调用 | $tool_calls |" >> "$log_file"
    echo "| 会话评分 | $score/100 |" >> "$log_file"
    echo "" >> "$log_file"
}

# --- 更新统计数据 ---
update_stats_csv() {
    local stats_json=$1
    local score=$2

    local stats_file="$STATS_DIR/session_stats.csv"
    local timestamp=$(echo "$stats_json" | grep -oP '"timestamp"\s*:\s*"\K[^"]*' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')
    local session_id=$(echo "$stats_json" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
    local files_modified=$(echo "$stats_json" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
    local tool_calls=$(echo "$stats_json" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

    # 如果文件不存在，创建头部
    if [ ! -f "$stats_file" ]; then
        echo "timestamp,session_id,score,files_modified,tool_calls" > "$stats_file"
    fi

    echo "$timestamp,$session_id,$score,$files_modified,$tool_calls" >> "$stats_file"
}

# --- 更新偏好文件 ---
update_preferences() {
    local prefs_file="$PREFS_DIR/user-preferences.md"

    # 如果偏好文件不存在，创建基础结构
    if [ ! -f "$prefs_file" ]; then
        cat > "$prefs_file" << 'HEREDOC'
# 用户偏好记录

此文件由 maintainer（星星）智能体维护。

---

## 工作风格偏好

| 偏好 | 权重 | 来源会话 | 备注 |
|------|------|---------|------|
HEREDOC
    fi

    # 记录本次会话更新时间
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "" >> "$prefs_file"
    echo "<!-- last-updated: $timestamp -->" >> "$prefs_file"
}

# --- 执行主流程 ---
STATS_JSON=$(collect_real_stats)

FILES_MODIFIED=$(echo "$STATS_JSON" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
TOOL_CALLS=$(echo "$STATS_JSON" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
ERROR_COUNT=$(echo "$STATS_JSON" | grep -oP '"error_count"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

SCORE=$(calculate_score "$FILES_MODIFIED" "$TOOL_CALLS" "$ERROR_COUNT")

# 执行各项操作
compress_logs
write_session_log "$STATS_JSON" "$SCORE"
update_stats_csv "$STATS_JSON" "$SCORE"
update_preferences

# --- 输出会话总结 ---
SESSION_ID=$(echo "$STATS_JSON" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")

echo ""
echo "## 会话结束总结"
echo ""
echo "**Session ID**: ${SESSION_ID:0:16}..."
echo "**文件修改**: $FILES_MODIFIED 个"
echo "**工具调用**: $TOOL_CALLS 次"
echo ""
echo "### 会话评分"
echo ""

# 评分等级
if [ "$SCORE" -ge 80 ]; then
    GRADE="优秀"
elif [ "$SCORE" -ge 60 ]; then
    GRADE="良好"
elif [ "$SCORE" -ge 40 ]; then
    GRADE="一般"
else
    GRADE="待改进"
fi

echo "| 指标 | 数值 |"
echo "|------|------|"
echo "| 总分 | $SCORE/100 |"
echo "| 等级 | $GRADE |"
echo ""
echo "### 已保存"
echo ""
echo "- 会话日志: \`docs/logs/session-$(date '+%Y-%m-%d').md\`"
echo "- 统计数据: \`.claude/stats/session_stats.csv\`"
echo "- 用户偏好: \`.claude/preferences/user-preferences.md\`"
echo ""

exit 0
