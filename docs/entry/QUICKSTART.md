# MyAI 快速开始指南

## 核心概念

MyAI 是一个 **AI 辅助开发环境**，通过 5 个智能体协作完成开发任务。

### 五大智能体

```
planner（调度） → coder（编码） → architect（审核） → tester（验证） → maintainer（评分）
     蓝              绿              红              橙              紫
```

| 智能体 | 代号 | 一句话理解 |
|--------|------|-----------|
| **planner** | 魔术师 | 接到任务后拆解成子任务，分配给合适的智能体 |
| **coder** | 战车 | 按规范写代码，最小化改动 |
| **architect** | 皇帝 | 守门人——涉及架构变更必须经它审核 |
| **tester** | 正义 | 并行验证，用置信度判断结果可信度 |
| **maintainer** | 星星 | 记录日志、统计消耗、追踪偏好 |

### 置信度分级

| 等级 | 范围 | 行为 |
|------|------|------|
| 待验证 | < 80% | 必须人工确认 |
| 疑似 | 80-89% | 警告，建议人工复核 |
| 确认 | >= 90% | 可信，自动通过 |

## 场景流程速查

### 特性开发（`spec/feature-dev.md`）

```
Phase 1 需求接收 → Phase 2 技术调研 → Phase 3 方案澄清 [确认门①]
→ Phase 4 架构设计 [确认门②] → Phase 5 编码实现 [确认门③]
→ Phase 6 测试验证 → Phase 7 收尾
```

- 3 个用户确认门（Phase 3/4/5），防止跑偏
- Phase 2 可并行探索多个技术方案
- Phase 6 tester 多维度并行验证

### 新项目初始化（`spec/project-init.md`）

```
Phase 1 需求收集 → Phase 2 架构设计 [确认门]
→ Phase 3 脚手架搭建 → Phase 4 验证交付
```

- architect 提供 3 种方案：最小改动 / 干净架构 / 务实平衡

### Bug 修复（`spec/bug-fix.md`）

```
Phase 1 问题定位 → Phase 2 修复方案 → Phase 3 编码修复 → Phase 4 测试验证
```

- 并行验证 + 回归测试

### 技能开发（`spec/skill-develop.md`）

```
Phase 1 需求定义 → Phase 2 技能设计 → Phase 3 编码实现
→ Phase 4 测试验证 → Phase 5 归档发布
```

- 使用 skill-creator 辅助，完成后更新 source.map

## Hook 退出码协议

所有 Hook 脚本返回值必须遵循：

| 退出码 | 含义 | AI 行为 |
|--------|------|---------|
| `0` | 放行 | 继续执行 |
| `1` | 警告 | 记录警告，继续执行 |
| `2` | 阻止 | 停止当前操作，修正后重试 |

## 安全红线（9 种禁止模式）

1. 命令注入（`os.system(user_input)`）
2. XSS（未转义 HTML 输出）
3. eval/exec（动态代码执行）
4. pickle 反序列化（不可信数据）
5. 硬编码密钥（明文密码/Token）
6. SQL 注入（字符串拼接 SQL）
7. 路径遍历（未校验 `../`）
8. 不安全下载（无校验的文件写入）
9. 危险 HTML（`dangerouslySetInnerHTML`）

## 常用文件路径

| 需求 | 文件 |
|------|------|
| 了解项目全貌 | `docs/source.map` |
| 查看 AI 行为规则 | `rules/ai-rules.md` |
| 查看项目开发规则 | `rules/project-rules.md` |
| 查看架构变更历史 | `docs/arch-changelog.md` |
| 查看会话进度 | `docs/progress.md` |
| 查看 Hook 注册表 | `hooks/INDEX.md` |
| 查看命令集索引 | `commands/INDEX.md` |
| 查看可用技能 | `skills/` |
