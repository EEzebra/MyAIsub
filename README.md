# MyAI

AI 辅助开发环境，具备智能体协作、命令集、知识库、规则约束和技能扩展能力。

## 项目结构

```
MyAI/
├── README.md              # 项目说明（本文件）
├── .agentsspaces/         # Agent 空间配置
├── agents/                # 智能体定义
│   ├── planner/           #   计划智能体 — 任务指挥中枢
│   ├── coder/             #   编码智能体 — 代码执行引擎
│   ├── tester/            #   测试智能体 — 质量守卫者
│   ├── architect/         #   架构师智能体 — 核心守门人
│   └── maintainer/        #   项目维护智能体 — 用户体验引擎
├── commons/               # 命令集（集中存放命令脚本）
├── docs/                  # 知识库
│   ├── entry/             #   入口文件夹（远端同步入口）
│   ├── source.map         #   MyAI 地图文件
│   ├── task_plan.md       #   任务规划
│   ├── findings.md        #   调研发现
│   └── progress.md        #   进度日志
├── hooks/                 # 条件触发的命令脚本
├── rules/                 # 规则（AI 规则、项目规则）
├── skills/                # 技能归档（19 个技能）
└── spec/                  # 场景流程文件
```

## 智能体

| 智能体 | 代号 | 角色 | 核心职责 |
|--------|------|------|----------|
| planner | 魔术师 | 任务指挥中枢 | 任务理解、拆解规划、依赖分析、智能体调度、进度跟踪 |
| coder | 战车 | 代码执行引擎 | 代码编写、规则遵守、架构约束、技能调用、增量实现 |
| tester | 正义 | 质量守卫者 | 用例设计、功能验证、问题报告、回归验证、结果记录 |
| architect | 皇帝 | 核心守门人 | 架构定义、完整性监督、强制审核、分级风险处理 |
| maintainer | 星星 | 用户体验引擎 | 日志管理、Token 统计、偏好追踪、规则提取、会话评分 |

## 协作流程

```
用户任务 → planner(规划调度) → coder(编码) → architect(架构审核) → tester(验证) → maintainer(评分)
```

## 技能清单

algorithmic-art, brand-guidelines, canvas-design, claude-api, doc-coauthoring, docx, frontend-design, internal-comms, mcp-builder, pdf, planning-with-files, pptx, skill-creator, slack-gif-creator, theme-factory, web-artifacts-builder, webapp-testing, xlsx

## 规则体系

- **全局规则** > 项目规则 > 场景规则
- 所有架构变更必须经过架构师智能体审核
- 编码智能体不得绕过架构审核流程
