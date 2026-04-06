#!/bin/bash
# intent-classify.sh — 意图识别 Hook
# 事件: UserPromptSubmit（用户提交消息时）
# 功能: 分析用户意图，推荐合适的智能体
#
# 输入:
#   stdin - JSON 格式的用户消息
# 输出:
#   stdout - 意图分析结果和智能体推荐
# 退出码:
#   0 — 放行（始终放行，仅提供推荐）

set -euo pipefail

# --- 配置 ---
PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
LOG_DIR="$PROJECT_DIR/.claude/logs"
mkdir -p "$LOG_DIR"

# 从 stdin 读取用户消息
INPUT_JSON=$(cat)

# 提取用户消息内容
USER_MESSAGE=$(echo "$INPUT_JSON" | grep -oP '"content"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")
if [ -z "$USER_MESSAGE" ]; then
    # 尝试另一种格式
    USER_MESSAGE=$(echo "$INPUT_JSON" | grep -oP '"message"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")
fi

# 意图关键词映射
declare -A INTENT_KEYWORDS=(
    ["planner"]="规划|拆解|计划|任务|安排|设计.*流程|需求.*分析|项目.*管理|帮我.*分析"
    ["coder"]="写代码|写.*功能|实现|修改代码|重构代码|添加功能|修复|编写|开发|编码|创建.*模块|构建"
    ["tester"]="测试|验证|检查质量|单元测试|集成测试|覆盖率|bug检测|质量保证"
    ["architect"]="架构|设计.*结构|模块划分|技术选型|系统设计|架构重构|整体设计"
    ["maintainer"]="维护|清理|优化|日志|统计|评分|文档|更新.*记录|整理"
    ["coordinator"]="并行|同时|多个.*任务|聚合|协调|批量处理"
)

# 分析意图并计算置信度
declare -A CONFIDENCE=()
RECOMMENDED_AGENT=""
MAX_SCORE=0

for agent in "${!INTENT_KEYWORDS[@]}"; do
    pattern="${INTENT_KEYWORDS[$agent]}"
    # 统计匹配关键词数量
    matches=$(echo "$USER_MESSAGE" | grep -oiE "$pattern" | wc -l) || matches=0
    if [ "$matches" -gt 0 ]; then
        CONFIDENCE[$agent]=$((matches * 20))
        if [ "${CONFIDENCE[$agent]}" -gt 100 ]; then
            CONFIDENCE[$agent]=100
        fi
        if [ "${CONFIDENCE[$agent]}" -gt "$MAX_SCORE" ]; then
            MAX_SCORE="${CONFIDENCE[$agent]}"
            RECOMMENDED_AGENT="$agent"
        fi
    fi
done

# 默认推荐
if [ -z "$RECOMMENDED_AGENT" ]; then
    RECOMMENDED_AGENT="planner"
    CONFIDENCE[$RECOMMENDED_AGENT]=30
fi

# --- 输出结果 ---
echo ""
echo "## 意图分析"
echo ""
echo "**用户消息**: ${USER_MESSAGE:0:100}..."
echo ""
echo "### 智能体推荐"
echo ""
echo "| Agent | Codename | 置信度 | 匹配关键词 |"
echo "|-------|----------|--------|------------|"

# 按置信度排序输出
for agent in planner coder tester architect maintainer coordinator; do
    if [ -n "${CONFIDENCE[$agent]:-}" ]; then
        case $agent in
            planner) codename="魔术师" ;;
            coder) codename="战车" ;;
            tester) codename="正义" ;;
            architect) codename="皇帝" ;;
            maintainer) codename="星星" ;;
            coordinator) codename="教皇" ;;
        esac
        confidence="${CONFIDENCE[$agent]}"
        marker=""
        if [ "$agent" = "$RECOMMENDED_AGENT" ]; then
            marker=" ★ 推荐"
        fi
        echo "| $agent | $codename | ${confidence}%$marker | ${INTENT_KEYWORDS[$agent]} |"
    fi
done

echo ""
echo "### 建议操作"
echo ""
echo "\`\`\`"
echo "# 调用推荐的智能体"
echo "使用 Agent 工具，subagent_type='general-purpose', prompt 中指定角色为 $RECOMMENDED_AGENT"
echo "\`\`\`"
echo ""

# 记录日志
LOG_FILE="$LOG_DIR/intent-classify.log"
echo "$(date '+%Y-%m-%d %H:%M:%S') | recommended=$RECOMMENDED_AGENT | confidence=$MAX_SCORE | message=${USER_MESSAGE:0:50}" >> "$LOG_FILE"

exit 0
