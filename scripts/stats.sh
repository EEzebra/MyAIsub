#!/bin/bash
# 项目代码统计脚本
# 统计文件数量和代码行数

set -e

# 默认统计当前目录
TARGET_DIR="${1:-.}"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查目录是否存在
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}错误: 目录 '$TARGET_DIR' 不存在${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}   项目代码统计${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "目标目录: ${YELLOW}$TARGET_DIR${NC}"
echo ""

# 排除的目录模式
EXCLUDE_PATTERN="/\.git/|/node_modules/|/__pycache__/|/\.venv/|/venv/|/dist/|/build/|/\.idea/|/\.agentsspaces/|/\.claude/"

# 常见代码文件扩展名
CODE_EXTENSIONS="sh py js ts jsx tsx go java c cpp h rs php rb"

# 统计函数
count_lines() {
    local file="$1"
    local ext="${file##*.}"
    
    case "$ext" in
        sh|py)
            # 排除空行和 # 注释
            grep -v '^\s*$' "$file" 2>/dev/null | grep -v '^\s*#' | wc -l
            ;;
        js|ts|jsx|tsx|go|java|c|cpp|h|rs|php)
            # 排除空行和 // 注释
            grep -v '^\s*$' "$file" 2>/dev/null | grep -v '^\s*//' | wc -l
            ;;
        rb)
            # 排除空行和 # 注释
            grep -v '^\s*$' "$file" 2>/dev/null | grep -v '^\s*#' | wc -l
            ;;
        *)
            # 默认只排除空行
            grep -v '^\s*$' "$file" 2>/dev/null | wc -l
            ;;
    esac
}

echo -e "${YELLOW}>>> 文件数量统计 (按扩展名分类)${NC}"
echo "----------------------------------------"

total_files=0
declare -A ext_counts

# 遍历所有文件（排除特定目录）
while IFS= read -r -d '' file; do
    ext="${file##*.}"
    [[ -z "$ext" || "$file" =~ $EXCLUDE_PATTERN ]] && continue
    ext_counts["$ext"]=$((ext_counts["$ext"] + 1))
    total_files=$((total_files + 1))
done < <(find "$TARGET_DIR" -type f -print0 2>/dev/null)

# 输出统计结果
for ext in "${!ext_counts[@]}"; do
    printf "  %-15s %d 个文件\n" ".$ext" "${ext_counts[$ext]}"
done | sort -k2 -rn

echo "----------------------------------------"
echo -e "总计: ${GREEN}$total_files${NC} 个文件"
echo ""

echo -e "${YELLOW}>>> 代码行数统计 (排除空行和注释)${NC}"
echo "----------------------------------------"

total_lines=0
declare -A ext_lines

# 统计代码行数
for ext in $CODE_EXTENSIONS; do
    count=0
    while IFS= read -r -d '' file; do
        [[ "$file" =~ $EXCLUDE_PATTERN ]] && continue
        lines=$(count_lines "$file")
        count=$((count + lines))
    done < <(find "$TARGET_DIR" -type f -name "*.$ext" -print0 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        ext_lines["$ext"]=$count
        total_lines=$((total_lines + count))
    fi
done

# 输出行数统计
for ext in "${!ext_lines[@]}"; do
    printf "  %-15s %d 行\n" ".$ext" "${ext_lines[$ext]}"
done | sort -k2 -rn

echo "----------------------------------------"
echo -e "代码总行数: ${GREEN}$total_lines${NC} 行"
echo ""

# 目录大小统计
echo -e "${YELLOW}>>> 目录概览${NC}"
echo "----------------------------------------"
dir_count=$(find "$TARGET_DIR" -type d 2>/dev/null | grep -Ev "$EXCLUDE_PATTERN" | wc -l)
echo -e "  目录数量: $dir_count"
echo ""

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}统计完成!${NC}"
