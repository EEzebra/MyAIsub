# 架构变更日志

记录所有 MyAI 架构变更，无论风险等级。

## 格式
```
[日期] [风险等级] [变更描述] [影响范围] [决策者] [审核者]
```

## 变更记录

### 2026-04-03
| 风险等级 | 变更描述 | 影响范围 | 决策者 | 审核者 |
|----------|----------|----------|--------|--------|
| 低风险 | 创建初始项目骨架（8 目录 + 文件） | 全局 | 用户 + planner | — |
| 低风险 | 升级 AGENT.md 增加 YAML Frontmatter | agents/ | 用户 + planner | — |
| 低风险 | 升级 hooks 体系为事件驱动 + 退出码协议 | hooks/ | 用户 + planner | — |
| 低风险 | 新增安全监控 Hook（security-check.sh） | hooks/ | 用户 + planner | — |
| 低风险 | 新增 feature-dev 场景流程（7 阶段） | spec/ | 用户 + planner | — |
| 低风险 | 新增 architect 多方案设计能力 | agents/architect/ | 用户 + planner | — |
| 低风险 | 新增 tester 并行验证 + 置信度过滤 | agents/tester/ | 用户 + planner | — |
| 低风险 | 新增 maintainer 5 维度评分体系 | agents/maintainer/ | 用户 + planner | — |
