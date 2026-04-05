#!/bin/bash
# security-check.sh — 安全监控 Hook
# 事件: PreToolUse（工具调用前）
# 检测代码中的安全风险模式
#
# 退出码:
#   0 — 放行
#   1 — 警告（记录但不阻止）
#   2 — 阻止（必须修正后才可继续）

set -euo pipefail

# --- 配置 ---
RISK_HIGH=2   # 阻止
RISK_MED=1    # 警告
RISK_LOW=0    # 放行

# 目标文件（从环境变量或参数获取）
TARGET_FILE="${1:-}"
TEMP_DIR="${TEMP_DIR:-/tmp/myai-security}"
LOG_FILE="${TEMP_DIR}/security-check.log"

mkdir -p "$TEMP_DIR"

# 如果没有目标文件，放行
if [ -z "$TARGET_FILE" ] || [ ! -f "$TARGET_FILE" ]; then
    exit $RISK_LOW
fi

EXIT_CODE=$RISK_LOW
WARNINGS=()
BLOCKERS=()

# --- 高风险模式检测（退出码 2）---

# 1. 命令注入
if grep -nE '(os\.system\s*\(\s*[^)]*\+|subprocess\.\w+\s*\([^)]*shell\s*=\s*True|eval\s*\(' "$TARGET_FILE" >/dev/null 2>&1; then
    BLOCKERS+=("命令注入: 检测到 os.system/subprocess/eval 使用未受控输入")
fi

# 2. eval/exec 动态执行
if grep -nE '\beval\s*\(|\bexec\s*\(' "$TARGET_FILE" >/dev/null 2>&1; then
    BLOCKERS+=("eval/exec: 检测到动态代码执行")
fi

# 3. pickle 反序列化
if grep -nE 'pickle\.loads?\s*\(' "$TARGET_FILE" >/dev/null 2>&1; then
    BLOCKERS+=("pickle 反序列化: 处理不可信数据可能导致任意代码执行")
fi

# 4. 硬编码密钥
if grep -nE '(password|passwd|api_key|apikey|secret|token)\s*=\s*['\''"][^'\''"]{8,}['\''"]' "$TARGET_FILE" >/dev/null 2>&1; then
    BLOCKERS+=("硬编码密钥: 检测到可能的明文密码或 API Key")
fi

# 5. SQL 注入
if grep -nE '(SELECT|INSERT|UPDATE|DELETE|DROP).*\+\s*(request|input|params|user)' "$TARGET_FILE" >/dev/null 2>&1; then
    BLOCKERS+=("SQL 注入: 检测到字符串拼接 SQL")
fi

# --- 中风险模式检测（退出码 1）---

# 6. XSS（innerHTML、未转义输出）
if grep -nE '(innerHTML|dangerouslySetInnerHTML|\.html\()' "$TARGET_FILE" >/dev/null 2>&1; then
    WARNINGS+=("XSS 风险: 检测到直接 HTML 赋值，请确保数据已转义")
fi

# 7. 路径遍历
if grep -nE '(open\s*\(|read|write).*\+\s*(request|input|params|user|os\.path\.join.*\.\.)' "$TARGET_FILE" >/dev/null 2>&1; then
    WARNINGS+=("路径遍历: 检测到可能未校验的路径拼接")
fi

# 8. 不安全下载
if grep -nE 'requests\.(get|post)\s*\(.*\n.*open\s*\(' "$TARGET_FILE" >/dev/null 2>&1; then
    WARNINGS+=("不安全下载: 检测到网络下载后直接写入文件，建议校验内容")
fi

# --- 结果判定 ---

if [ ${#BLOCKERS[@]} -gt 0 ]; then
    EXIT_CODE=$RISK_HIGH
    echo "[SECURITY BLOCKED] $TARGET_FILE"
    for b in "${BLOCKERS[@]}"; do
        echo "  ✗ $b"
    done
elif [ ${#WARNINGS[@]} -gt 0 ]; then
    EXIT_CODE=$RISK_MED
    echo "[SECURITY WARNING] $TARGET_FILE"
    for w in "${WARNINGS[@]}"; do
        echo "  ⚠ $w"
    done
fi

# 记录日志
echo "$(date '+%Y-%m-%d %H:%M:%S') [exit=$EXIT_CODE] $TARGET_FILE" >> "$LOG_FILE"

exit $EXIT_CODE
