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
echo "[1/5] 检查目录结构..."

REQUIRED_DIRS=(
  "agents/planner"
  "agents/coder"
  "agents/tester"
  "agents/architect"
  "agents/maintainer"
  "agents/coordinator"
  "rules"
  "hooks"
  "commands"
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
echo "[2/5] 检查关键文件..."

REQUIRED_FILES=(
  "agents/planner/AGENT.md"
  "agents/coder/AGENT.md"
  "agents/tester/AGENT.md"
  "agents/architect/AGENT.md"
  "agents/maintainer/AGENT.md"
  "agents/coordinator/AGENT.md"
  "rules/ai-rules.md"
  "rules/project-rules.md"
  "hooks/INDEX.md"
  "commands/INDEX.md"
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

# --- 阶段 2.5: Agent 结构完整性检查 ---
echo ""
echo "[2.5/5] 检查 Agent 结构完整性..."

AGENT_RULES_MISSING=0
for agent_dir in "$MYAI_ROOT/agents"/*; do
  if [ -d "$agent_dir" ]; then
    agent_name=$(basename "$agent_dir")
    
    # 检查 AGENT.md
    if [ -f "$agent_dir/AGENT.md" ]; then
      echo "  ✓ $agent_name/AGENT.md"
    else
      echo "  ✗ $agent_name/AGENT.md 缺失"
      AGENT_RULES_MISSING=$((AGENT_RULES_MISSING + 1))
    fi
    
    # 检查 rules.md
    if [ -f "$agent_dir/rules.md" ]; then
      echo "  ✓ $agent_name/rules.md"
    else
      echo "  ✗ $agent_name/rules.md 缺失"
      AGENT_RULES_MISSING=$((AGENT_RULES_MISSING + 1))
    fi
  fi
done

if [ $AGENT_RULES_MISSING -gt 0 ]; then
  echo ""
  echo "⚠️  Agent 结构不完整，缺少 $AGENT_RULES_MISSING 个必要文件。"
fi

# --- 阶段 3: Hook 和 Command 脚本权限 ---
echo ""
echo "[3/5] 配置脚本权限..."

# Hook 脚本权限
HOOK_DIR="$MYAI_ROOT/hooks"
if [ -d "$HOOK_DIR" ]; then
  HOOK_COUNT=0
  for hook in "$HOOK_DIR"/*.sh; do
    if [ -f "$hook" ]; then
      chmod +x "$hook"
      echo "  ✓ hooks/$(basename "$hook") — 已赋予执行权限"
      HOOK_COUNT=$((HOOK_COUNT + 1))
    fi
  done
  if [ $HOOK_COUNT -eq 0 ]; then
    echo "  ℹ️  暂无 .sh Hook 脚本"
  fi
else
  echo "  ✗ hooks/ 目录不存在"
fi

# Command 脚本权限
COMMAND_DIR="$MYAI_ROOT/commands"
if [ -d "$COMMAND_DIR" ]; then
  CMD_COUNT=0
  for cmd in "$COMMAND_DIR"/*.sh; do
    if [ -f "$cmd" ]; then
      chmod +x "$cmd"
      echo "  ✓ commands/$(basename "$cmd") — 已赋予执行权限"
      CMD_COUNT=$((CMD_COUNT + 1))
    fi
  done
  if [ $CMD_COUNT -eq 0 ]; then
    echo "  ℹ️  暂无 .sh 命令脚本"
  fi
fi

# --- 阶段 4: .claude 目录初始化 ---
echo ""
echo "[4/5] 初始化 .claude 目录..."

CLAUDE_DIR="$MYAI_ROOT/.claude"
if [ ! -d "$CLAUDE_DIR" ]; then
  mkdir -p "$CLAUDE_DIR"
  echo "  ✓ 创建 .claude/ 目录"
else
  echo "  ✓ .claude/ 目录已存在"
fi

# 创建子目录
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/scripts"
echo "  ✓ .claude/commands/ 目录已就绪"
echo "  ✓ .claude/scripts/ 目录已就绪"

# 创建会话环境文件（如不存在）
SESSION_ENV="$CLAUDE_DIR/session.env"
if [ ! -f "$SESSION_ENV" ]; then
  touch "$SESSION_ENV"
  echo "# MyAI Session Environment Variables" > "$SESSION_ENV"
  echo "# 此文件由 session-init.sh 和 session-state.sh 维护" >> "$SESSION_ENV"
  echo "  ✓ 创建 .claude/session.env"
else
  echo "  ✓ .claude/session.env 已存在"
fi

# --- 阶段 5: 架构健康检查 ---
echo ""
echo "[5/5] 架构健康检查..."

if [ -f "$MYAI_ROOT/commands/arch-health-check.sh" ]; then
  bash "$MYAI_ROOT/commands/arch-health-check.sh" || echo "  ⚠️  架构健康检查发现问题，请查看上方详情"
else
  echo "  ℹ️  架构健康检查脚本不存在，跳过"
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
echo "  4. 运行 commands/arch-health-check.sh 随时检查架构健康"
echo "========================================="
