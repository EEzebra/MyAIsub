# 场景：技能开发

## 触发条件
用户请求开发新技能或修改现有技能。

## 参与智能体
- planner（规划）、coder（实现）、architect（审核）、tester（验证）

## 执行步骤

### Step 1: 需求定义（planner）
- 接收技能需求描述
- 分析技能用途、适用场景
- 定义技能输入输出规范
- 参考现有 skills/ 下 19 个技能的模式

### Step 2: 技能骨架创建（coder）
- 使用 skill-creator 技能辅助创建
- 按标准结构创建技能目录
- 编写 SKILL.md 定义文件
- 编写技能实现代码

### Step 3: 审核与验证（architect + tester）
- architect 审核技能是否符合目录规范
- tester 验证技能功能正确性
- 更新 source.map 技能索引

### Step 4: 注册与归档（planner）
- 在 source.map 中注册新技能
- 在 hooks/ 中注册相关 Hook（如需要）
- 记录到 progress.md

### Step 5: 总结（maintainer）
- 评估技能开发过程
- 提取经验到智能体规则

## 输出物
- 技能目录（skills/<name>/）
- SKILL.md 定义文件
- 测试报告
- 更新后的 source.map
