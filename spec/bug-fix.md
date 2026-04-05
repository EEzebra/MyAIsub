# 场景：Bug 修复

## 触发条件
用户报告 Bug 或请求修复已知问题。

## 参与智能体
- planner（定位）、coder（修复）、tester（验证）

## 执行步骤

### Step 1: 问题定位（planner）
- 接收 Bug 描述
- 使用代码搜索定位问题代码
- 分析问题根因和影响范围
- 记录到 findings.md

### Step 2: 修复方案（coder）
- 设计修复方案（优先最小化修改）
- 评估是否涉及架构变更
  - 涉及架构 → 调用 architect 审核
  - 不涉及 → 直接修复
- 实施修复

### Step 3: 验证（tester）
- **并行验证：**
  - 修复点功能测试
  - 回归测试（确认无新问题）
  - Linter 检查
- 置信度过滤

### Step 4: 总结（planner）
- 更新 progress.md
- 记录 Bug 修复经验到 findings.md

## 输出物
- 修复后的代码
- 测试报告
- Bug 根因分析记录
