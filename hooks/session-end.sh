#!/bin/bash
# session-end.sh — 会话结束 Hook
# 事件: Stop（会话结束时）
# 功能: 触发日志压缩、会话评分、状态持久化
#
# 输入:
#   stdin - JSON 格式的会话信息
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
mkdir -p "$LOG_DIR" "$STATS_DIR"

# 从 stdin 读取会话信息
INPUT_JSON=$(cat)

# 提取会话数据
SESSION_ID=$(echo "$INPUT_JSON" | grep -oP '"session_id"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
DURATION=$(echo "$INPUT_JSON" | grep -oP '"duration"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
TOOL_CALLS=$(echo "$INPUT_JSON" | grep -oP '"tool_calls"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")
FILES_MODIFIED=$(echo "$INPUT_JSON" | grep -oP '"files_modified"\s*:\s*\K[0-9]+' 2>/dev/null || echo "0")

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
    local score=0

    # 基础分：完成会话
    score=$((score + 10))

    # 工具调用效率（每 5 次调用 +1 分，最高 20 分）
    local tool_score=$((TOOL_CALLS / 5))
    if [ $tool_score -gt 20 ]; then
        tool_score=20
    fi
    score=$((score + tool_score))

    # 文件修改分（每个文件 +2 分，最高 30 分）
    local file_score=$((FILES_MODIFIED * 2))
    if [ $file_score -gt 30 ]; then
        file_score=30
    fi
    score=$((score + file_score))

    # 持续时间分（每分钟 +1 分，最高 20 分）
    local duration_min=$((DURATION / 60))
    if [ $duration_min -gt 20 ]; then
        duration_min=20
    fi
    score=$((score + duration_min))

    # 检查是否有错误日志
    local error_count=$(find "$LOG_DIR" -name "*.log" -exec grep -l "error\|ERROR\|failed\|FAILED" {} \; 2>/dev/null | wc -l)
    if [ "$error_count" -gt 0 ]; then
        score=$((score - error_count * 5))
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

# --- 统计汇总 ---
summarize_stats() {
    local stats_file="$STATS_DIR/session_stats.csv"

    # 如果文件不存在，创建头部
    if [ ! -f "$stats_file" ]; then
        echo "timestamp,session_id,score,duration,tool_calls,files_modified" > "$stats_file"
    fi

    local score=$(calculate_score)
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$timestamp,$SESSION_ID,$score,$DURATION,$TOOL_CALLS,$FILES_MODIFIED" >> "$stats_file"

    echo $score
}

# --- 执行 ---
compress_logs
SCORE=$(summarize_stats)

# --- 输出会话总结 ---
echo ""
echo "## 会话结束总结"
echo ""
echo "**Session ID**: ${SESSION_ID:0:8}..."
echo "**持续时间**: $((DURATION / 60)) 分钟"
echo "**工具调用**: $TOOL_CALLS 次"
echo "**文件修改**: $FILES_MODIFIED 个"
echo ""
echo "### 会话评分"
echo ""

# 评分等级
if [ "$SCORE" -ge 80 ]; then
    GRADE="优秀"
    EMOJI="🌟"
elif [ "$SCORE" -ge 60 ]; then
    GRADE="良好"
    EMOJI="✨"
elif [ "$SCORE" -ge 40 ]; then
    GRADE="一般"
    EMOJI="⚡"
else
    GRADE="待改进"
    EMOJI="💡"
fi

echo "| 指标 | 数值 |"
echo "|------|------|"
echo "| 总分 | $SCORE/100 |"
echo "| 等级 | $EMOJI $GRADE |"
echo ""
echo "### 统计已保存"
echo ""
echo "- 日志压缩: 已清理 7 天前的日志"
echo "- 统计记录: \`$STATS_DIR/session_stats.csv\`"
echo ""

# --- 持久化环境变量 ---
ENV_FILE="$SESSION_DIR/session.env"
if [ -f "$ENV_FILE" ]; then
    # 清理过期的环境变量
    sed -i '/^#/d' "$ENV_FILE" 2>/dev/null || true
fi

exit 0
