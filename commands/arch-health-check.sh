#!/bin/bash
# arch-health-check.sh — 架构健康检查脚本
# 用途: 检查 MyAI 项目架构的完整性和规范性
# 用法: bash commands/arch-health-check.sh

set -e

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MYAI_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================="
echo "  MyAI 架构健康检查"
echo "  项目根目录: $MYAI_ROOT"
echo "========================================="

ERRORS=0
WARNINGS=0

# --- 检查函数 ---

check_pass() {
    echo "  ✅ $1"
}

check_warn() {
    echo "  ⚠️  $1"
    WARNINGS=$((WARNINGS + 1))
}

check_fail() {
    echo "  ❌ $1"
    ERRORS=$((ERRORS + 1))
}

# --- 1. Agent 目录结构检查 ---

echo ""
echo "[1] Agent 目录结构检查"

AGENT_DIRS=$(find "$MYAI_ROOT/agents" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)

if [ -z "$AGENT_DIRS" ]; then
    check_fail "agents/ 目录下没有任何 agent 目录"
else
    for agent_dir in $AGENT_DIRS; do
        agent_name=$(basename "$agent_dir")
        
        # 检查 AGENT.md
        if [ -f "$agent_dir/AGENT.md" ]; then
            check_pass "$agent_name/AGENT.md 存在"
        else
            check_fail "$agent_name/AGENT.md 缺失"
        fi
        
        # 检查 rules.md
        if [ -f "$agent_dir/rules.md" ]; then
            check_pass "$agent_name/rules.md 存在"
        else
            check_fail "$agent_name/rules.md 缺失"
        fi
        
        # 检查 AGENT.md frontmatter
        if [ -f "$agent_dir/AGENT.md" ]; then
            if head -5 "$agent_dir/AGENT.md" | grep -q "^---"; then
                if grep -q "^name:" "$agent_dir/AGENT.md" && \
                   grep -q "^description:" "$agent_dir/AGENT.md" && \
                   grep -q "^model:" "$agent_dir/AGENT.md"; then
                    check_pass "$agent_name/AGENT.md frontmatter 完整"
                else
                    check_warn "$agent_name/AGENT.md frontmatter 缺少必要字段 (name/description/model)"
                fi
            else
                check_warn "$agent_name/AGENT.md 缺少 YAML frontmatter"
            fi
        fi
    done
fi

# --- 2. 核心目录检查 ---

echo ""
echo "[2] 核心目录检查"

CORE_DIRS=("rules" "hooks" "commands" "skills" "spec" "docs" "docs/entry")
for dir in "${CORE_DIRS[@]}"; do
    if [ -d "$MYAI_ROOT/$dir" ]; then
        check_pass "$dir/ 目录存在"
    else
        check_fail "$dir/ 目录缺失"
    fi
done

# --- 3. 核心文件检查 ---

echo ""
echo "[3] 核心文件检查"

CORE_FILES=(
    "rules/ai-rules.md"
    "rules/project-rules.md"
    "hooks/INDEX.md"
    "commands/INDEX.md"
    "docs/entry/PROJECT.md"
    "docs/entry/setup.sh"
    "README.md"
)

for file in "${CORE_FILES[@]}"; do
    if [ -f "$MYAI_ROOT/$file" ]; then
        check_pass "$file 存在"
    else
        check_fail "$file 缺失"
    fi
done

# --- 4. 命名规范检查 ---

echo ""
echo "[4] 命名规范检查"

# 检查是否有大写目录名（应该用 kebab-case）
UPPER_DIRS=$(find "$MYAI_ROOT" -mindepth 1 -maxdepth 2 -type d -name "*[A-Z]*" 2>/dev/null | grep -v "^$MYAI_ROOT/docs\|^$MYAI_ROOT/skills" || true)
if [ -n "$UPPER_DIRS" ]; then
    for dir in $UPPER_DIRS; do
        rel_dir="${dir#$MYAI_ROOT/}"
        check_warn "目录命名可能不规范: $rel_dir (建议使用 kebab-case)"
    done
else
    check_pass "目录命名规范检查通过"
fi

# 检查 .md 文件命名（应该用 kebab-case 或全大写如 AGENT.md）
BAD_MD_FILES=$(find "$MYAI_ROOT" -name "*.md" -type f 2>/dev/null | while read -r file; do
    basename=$(basename "$file" .md)
    # 允许全大写的特殊文件如 AGENT.md, README.md, INDEX.md
    if [[ ! "$basename" =~ ^[A-Z]+$ ]] && [[ "$basename" =~ [A-Z] ]]; then
        echo "$file"
    fi
done || true)

if [ -n "$BAD_MD_FILES" ]; then
    for file in $BAD_MD_FILES; do
        rel_file="${file#$MYAI_ROOT/}"
        check_warn "文件命名可能不规范: $rel_file (建议使用 kebab-case 或全大写)"
    done
else
    check_pass "Markdown 文件命名规范检查通过"
fi

# --- 5. .claude 目录检查 ---

echo ""
echo "[5] .claude 目录检查"

if [ -d "$MYAI_ROOT/.claude" ]; then
    check_pass ".claude/ 目录存在"
    
    if [ -d "$MYAI_ROOT/.claude/commands" ]; then
        check_pass ".claude/commands/ 目录存在"
    else
        check_warn ".claude/commands/ 目录缺失"
    fi
else
    check_warn ".claude/ 目录缺失（Claude/CodeBuddy 兼容目录）"
fi

# --- 6. 变更日志检查 ---

echo ""
echo "[6] 变更日志检查"

if [ -f "$MYAI_ROOT/docs/arch-changelog.md" ]; then
    check_pass "docs/arch-changelog.md 存在"
else
    check_warn "docs/arch-changelog.md 缺失（建议创建以记录架构变更）"
fi

# --- 总结 ---

echo ""
echo "========================================="
echo "  检查完成"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo "  ❌ 错误: $ERRORS 个"
fi
if [ $WARNINGS -gt 0 ]; then
    echo "  ⚠️  警告: $WARNINGS 个"
fi
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "  ✅ 所有检查通过，架构健康！"
fi

echo "========================================="

# 返回码：有错误返回 1，否则返回 0
if [ $ERRORS -gt 0 ]; then
    exit 1
else
    exit 0
fi
