#!/bin/bash

# PreCompact Hook for MyAIsub
# Triggered before context compression
# Preserves critical information from the conversation

set -euo pipefail

# Read hook input from stdin
INPUT_JSON=$(cat)

# Extract key fields
TRIGGER=$(echo "$INPUT_JSON" | grep -o '"trigger"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')
CUSTOM_INSTRUCTIONS=$(echo "$INPUT_JSON" | grep -o '"custom_instructions"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)".*/\1/')

PROJECT_DIR="${CODEBUDDY_PROJECT_DIR:-$(pwd)}"
COMPACT_LOG="$PROJECT_DIR/docs/subagent-integration/compact-log.md"

# Ensure log directory exists
mkdir -p "$(dirname "$COMPACT_LOG")"

# Get current timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Check for active task plan
TASK_PLAN="$PROJECT_DIR/docs/subagent-integration/task_plan.md"
CURRENT_PHASE=""
if [ -f "$TASK_PLAN" ]; then
    CURRENT_PHASE=$(grep -A1 "## Current Phase" "$TASK_PLAN" 2>/dev/null | tail -1 | sed 's/^[[:space:]]*//')
fi

# Check for key decisions in findings
FINDINGS="$PROJECT_DIR/docs/subagent-integration/findings.md"
DECISIONS=""
if [ -f "$FINDINGS" ]; then
    DECISIONS=$(grep -A20 "## Technical Decisions" "$FINDINGS" 2>/dev/null | head -22)
fi

# Output preservation summary
cat <<EOF
## PreCompact Preservation Summary

**Trigger**: ${TRIGGER:-auto}
**Time**: $TIMESTAMP
**Current Phase**: ${CURRENT_PHASE:-unknown}

### Key Context to Preserve
- Task Plan: docs/subagent-integration/task_plan.md
- Findings: docs/subagent-integration/findings.md
- Progress: docs/subagent-integration/progress.md

### Current Decisions
${DECISIONS:-No decisions recorded yet}

### Post-Compact Instructions
After compression:
1. Re-read task_plan.md to restore context
2. Check progress.md for current status
3. Continue from current phase

---
*Compact trigger: $TRIGGER*
EOF

# Log the compression event
echo "- [$TIMESTAMP] Compact triggered: $TRIGGER" >> "$COMPACT_LOG"

exit 0
