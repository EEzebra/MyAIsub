#!/bin/bash
# architect-review.sh — 架构审核 Hook
# 事件: ArchitectureChange（架构变更请求时）
# 功能: 强制调用架构师智能体进行审核，确保架构变更符合规范
#
# 输入:
#   stdin - JSON 格式的变更信息
# 输出:
#   stdout - 审核要求和指引
# 退出码:
#   0 — 放行（已通过架构审核）
#   2 — 阻止（需要先进行架构审核）

set -euo pipefail

# --- 配置 ---
PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
ARCH_REVIEW_DIR="$PROJECT_DIR/docs/architecture/reviews"
mkdir -p "$ARCH_REVIEW_DIR"

# 从 stdin 读取变更信息
INPUT_JSON=$(cat)

# 提取变更详情
CHANGE_TYPE=$(echo "$INPUT_JSON" | grep -oP '"change_type"\s*:\s*"\K[^"]*' 2>/dev/null || echo "unknown")
TARGET_FILE=$(echo "$INPUT_JSON" | grep -oP '"file_path"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")
DESCRIPTION=$(echo "$INPUT_JSON" | grep -oP '"description"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")

# 检查是否已有最近的审核记录（避免重复审核）
RECENT_REVIEW="$ARCH_REVIEW_DIR/.recent_review"
SKIP_REVIEW=0

if [ -f "$RECENT_REVIEW" ]; then
    LAST_REVIEW=$(cat "$RECENT_REVIEW")
    # 5分钟内已审核过同一文件则跳过
    if [[ "$LAST_REVIEW" == *"$TARGET_FILE"* ]]; then
        SKIP_REVIEW=1
    fi
fi

if [ "$SKIP_REVIEW" -eq 1 ]; then
    echo "[架构审核] 该文件近期已审核，跳过重复审核"
    exit 0
fi

# --- 架构审核指引 ---
echo ""
echo "## 架构变更审核要求"
echo ""
echo "**变更类型**: $CHANGE_TYPE"
echo "**目标文件**: \`$TARGET_FILE\`"
echo "**描述**: ${DESCRIPTION:-无}"
echo ""
echo "### 审核检查项"
echo ""
echo "| 检查项 | 要求 |"
echo "|--------|------|"
echo "| 一致性 | 变更是否与现有架构风格一致 |"
echo "| 依赖影响 | 是否影响其他模块或智能体 |"
echo "| 向后兼容 | 是否破坏现有接口或行为 |"
echo "| 文档更新 | 相关文档是否需要同步更新 |"
echo "| 安全性 | 是否引入安全风险 |"
echo ""

# 检查是否需要强制审核
REQUIRES_REVIEW=0

# 敏感变更类型需要强制审核
declare -A SENSITIVE_CHANGES=(
    ["agent-definition"]=1
    ["hook-script"]=1
    ["architecture-doc"]=1
    ["project-config"]=1
    ["dependency-change"]=1
    ["api-change"]=1
)

if [ -n "${SENSITIVE_CHANGES[$CHANGE_TYPE]:-}" ]; then
    REQUIRES_REVIEW=1
fi

# 敏感文件路径需要强制审核
if [[ "$TARGET_FILE" =~ agents/.*AGENT\.md$ ]]; then
    REQUIRES_REVIEW=1
elif [[ "$TARGET_FILE" =~ hooks/.*\.sh$ ]]; then
    REQUIRES_REVIEW=1
elif [[ "$TARGET_FILE" =~ ^CLAUDE\.md$|^MEMORY\.md$ ]]; then
    REQUIRES_REVIEW=1
fi

if [ "$REQUIRES_REVIEW" -eq 1 ]; then
    echo "### ⚠ 强制审核要求"
    echo ""
    echo "此变更属于架构敏感操作，**必须**经过架构师智能体审核。"
    echo ""
    echo "### 执行审核"
    echo ""
    echo "\`\`\`"
    echo "# 调用架构师智能体进行审核"
    echo "使用 Agent 工具："
    echo "  subagent_type: 'general-purpose'"
    echo "  prompt: '以 architect 角色审核以下变更：$TARGET_FILE'"
    echo "\`\`\`"
    echo ""

    # 记录待审核状态
    PENDING_FILE="$ARCH_REVIEW_DIR/pending/$TARGET_FILE"
    mkdir -p "$(dirname "$PENDING_FILE")"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $CHANGE_TYPE | $DESCRIPTION" > "$PENDING_FILE"

    # 阻止操作，返回退出码 2
    exit 2
fi

# 非强制审核，记录并放行
echo "### 审核状态"
echo ""
echo "- **审核类型**: 可选审核"
echo "- **建议**: 如涉及架构决策，建议调用 architect 智能体确认"
echo ""

exit 0
