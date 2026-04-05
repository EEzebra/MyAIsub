#!/bin/bash
# MyAI 环境初始化脚本
# 用途：克隆项目后执行，完成本地环境配置
# 用法：bash docs/entry/setup.sh

set -e

MYAI_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
echo "========================================="
echo "  MyAI 环境初始化"
echo "  项目根目录: $MYAI_ROOT"
echo "========================================="

# --- 阶段 1: 目录结构检查 ---
echo ""
echo "[1/4] 检查目录结构..."

REQUIRED_DIRS=(
  "agents/planner"
  "agents/coder"
  "agents/tester"
  "agents/architect"
  "agents/maintainer"
  "rules"
  "hooks"
  "commons"
  "skills"
  "spec"
  "docs/entry"
)

MISSING=0
for dir in "${REQUIRED_DIRS[@]}"; do
  if [ ! -d "$MYAI_ROOT/$dir" ]; then
    echo "  ✗ 缺少目录: $dir"
    MISSING=$((MISSING + 1))
  else
    echo "  ✓ $dir"
  fi
done

if [ $MISSING -gt 0 ]; then
  echo ""
  echo "❌ 缺少 $MISSING 个必要目录，请检查项目完整性。"
  exit 1
fi

# --- 阶段 2: 关键文件检查 ---
echo ""
echo "[2/4] 检查关键文件..."

REQUIRED_FILES=(
  "agents/planner/AGENT.md"
  "agents/coder/AGENT.md"
  "agents/tester/AGENT.md"
  "agents/architect/AGENT.md"
  "agents/maintainer/AGENT.md"
  "rules/ai-rules.md"
  "rules/project-rules.md"
  "hooks/INDEX.md"
  "commons/INDEX.md"
  "spec/feature-dev.md"
  "spec/project-init.md"
  "spec/bug-fix.md"
  "spec/skill-develop.md"
  "docs/source.map"
  "docs/progress.md"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$MYAI_ROOT/$file" ]; then
    echo "  ✗ 缺少文件: $file"
    MISSING_FILES=$((MISSING_FILES + 1))
  else
    echo "  ✓ $file"
  fi
done

if [ $MISSING_FILES -gt 0 ]; then
  echo ""
  echo "⚠️  缺少 $MISSING_FILES 个文件，部分功能可能不可用。"
fi

# --- 阶段 3: Hook 脚本权限 ---
echo ""
echo "[3/4] 配置 Hook 脚本权限..."

HOOK_DIR="$MYAI_ROOT/hooks"
if [ -d "$HOOK_DIR" ]; then
  HOOK_COUNT=0
  for hook in "$HOOK_DIR"/*.sh; do
    if [ -f "$hook" ]; then
      chmod +x "$hook"
      echo "  ✓ $(basename "$hook") — 已赋予执行权限"
      HOOK_COUNT=$((HOOK_COUNT + 1))
    fi
  done
  if [ $HOOK_COUNT -eq 0 ]; then
    echo "  ℹ️  暂无 .sh Hook 脚本"
  fi
else
  echo "  ✗ hooks/ 目录不存在"
fi

# --- 完成 ---
echo ""
echo "========================================="
echo "  初始化完成！"
echo ""
echo "  下一步："
echo "  1. 阅读 docs/source.map 了解项目全貌"
echo "  2. 阅读 docs/entry/PROJECT.md 了解核心规则"
echo "  3. 根据任务类型参考 spec/ 下的场景流程"
echo "========================================="
