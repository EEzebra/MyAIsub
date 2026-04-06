#!/bin/bash
# arch-changelog.sh — 架构变更日志 Hook
# 事件: PostToolUse（工具调用后）
# 功能: 检测架构相关变更，自动记录到变更日志，敏感变更触发架构审核
#
# 输入:
#   stdin - JSON 格式的工具调用结果
# 输出:
#   stdout - 变更日志记录
# 退出码:
#   0 — 放行
#   1 — 警告（检测到潜在架构变更但无法自动记录）
#   2 — 阻止（需要架构审核）

set -euo pipefail

# --- 配置 ---
PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
CHANGELOG_FILE="$PROJECT_DIR/docs/architecture/CHANGELOG.md"
ARCH_REVIEW_SCRIPT="$PROJECT_DIR/hooks/architect-review.sh"

# 架构敏感文件模式
ARCH_SENSITIVE_PATTERNS=(
    "agents/.*/AGENT\.md"
    "hooks/.*\.sh"
    "docs/architecture/.*"
    "CLAUDE\.md"
    "MEMORY\.md"
    "\.claude/settings\.json"
)

# 从 stdin 读取工具调用结果
INPUT_JSON=$(cat)

# 提取工具名称和目标文件
TOOL_NAME=$(echo "$INPUT_JSON" | grep -oP '"tool"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")
TARGET_FILE=$(echo "$INPUT_JSON" | grep -oP '"file_path"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")
RESULT=$(echo "$INPUT_JSON" | grep -oP '"result"\s*:\s*"\K[^"]*' 2>/dev/null || echo "")

# 只处理写入类操作
if [[ "$TOOL_NAME" != "write_to_file" && "$TOOL_NAME" != "replace_in_file" && "$TOOL_NAME" != "edit_file" ]]; then
    exit 0
fi

# 检查是否为架构敏感文件
IS_ARCH_CHANGE=0
CHANGE_TYPE=""

for pattern in "${ARCH_SENSITIVE_PATTERNS[@]}"; do
    if [[ "$TARGET_FILE" =~ $pattern ]]; then
        IS_ARCH_CHANGE=1
        break
    fi
done

# 如果不是架构敏感文件，放行
if [ "$IS_ARCH_CHANGE" -eq 0 ]; then
    exit 0
fi

# 确定变更类型
if [[ "$TARGET_FILE" =~ AGENT\.md$ ]]; then
    CHANGE_TYPE="agent-definition"
elif [[ "$TARGET_FILE" =~ \.sh$ ]]; then
    CHANGE_TYPE="hook-script"
elif [[ "$TARGET_FILE" =~ architecture/ ]]; then
    CHANGE_TYPE="architecture-doc"
elif [[ "$TARGET_FILE" =~ CLAUDE\.md|MEMORY\.md ]]; then
    CHANGE_TYPE="project-config"
fi

# 创建 changelog 目录
mkdir -p "$(dirname "$CHANGELOG_FILE")"

# 生成变更记录
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
CHANGE_ENTRY=""

case "$CHANGE_TYPE" in
    "agent-definition")
        AGENT_NAME=$(basename "$(dirname "$TARGET_FILE")")
        CHANGE_ENTRY="### [$TIMESTAMP] Agent 定义变更

**文件**: \`$TARGET_FILE\`
**类型**: Agent 定义
**Agent**: $AGENT_NAME

**变更摘要**: Agent frontmatter 或规则已更新
"
        ;;
    "hook-script")
        HOOK_NAME=$(basename "$TARGET_FILE" .sh)
        CHANGE_ENTRY="### [$TIMESTAMP] Hook 脚本变更

**文件**: \`$TARGET_FILE\`
**类型**: Hook 脚本
**Hook**: $HOOK_NAME

**变更摘要**: Hook 脚本已更新
"
        ;;
    "architecture-doc")
        CHANGE_ENTRY="### [$TIMESTAMP] 架构文档变更

**文件**: \`$TARGET_FILE\`
**类型**: 架构文档

**变更摘要**: 架构文档已更新
"
        ;;
    "project-config")
        CHANGE_ENTRY="### [$TIMESTAMP] 项目配置变更

**文件**: \`$TARGET_FILE\`
**类型**: 项目配置

**变更摘要**: 项目级配置文件已更新
"
        ;;
esac

# 追加到 changelog
if [ -n "$CHANGE_ENTRY" ]; then
    # 如果文件不存在，创建头部
    if [ ! -f "$CHANGELOG_FILE" ]; then
        cat > "$CHANGELOG_FILE" << 'EOF'
# 架构变更日志

记录所有架构相关的变更历史。

---
EOF
    fi

    echo "" >> "$CHANGELOG_FILE"
    echo "$CHANGE_ENTRY" >> "$CHANGELOG_FILE"

    echo ""
    echo "## 架构变更检测"
    echo ""
    echo "**检测到架构相关变更**"
    echo ""
    echo "- **文件**: \`$TARGET_FILE\`"
    echo "- **变更类型**: $CHANGE_TYPE"
    echo "- **已记录至**: \`$CHANGELOG_FILE\`"
    echo ""

    # 调用架构审核 Hook
    if [ -x "$ARCH_REVIEW_SCRIPT" ]; then
        echo "### 触发架构审核..."
        echo ""

        # 构造审核输入
        REVIEW_INPUT=$(cat <<EOF
{
  "change_type": "$CHANGE_TYPE",
  "file_path": "$TARGET_FILE",
  "description": "架构敏感文件变更"
}
EOF
)

        # 调用审核脚本
        REVIEW_EXIT=0
        echo "$REVIEW_INPUT" | "$ARCH_REVIEW_SCRIPT" || REVIEW_EXIT=$?

        if [ $REVIEW_EXIT -eq 2 ]; then
            echo ""
            echo "---"
            echo "**需要架构审核才能继续**"
            echo ""
            echo "请使用 Agent 工具调用 architect 智能体进行审核："
            echo "\`\`\`"
            echo "subagent_type: 'general-purpose'"
            echo "prompt: '以 architect 角色审核变更: $TARGET_FILE'"
            echo "\`\`\`"
            exit 2
        fi
    else
        echo "> 建议：如果此变更涉及架构决策，请调用 architect 智能体进行审核。"
        echo ""
    fi
fi

exit 0
