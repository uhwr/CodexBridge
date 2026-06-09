# CodexBridge

CodexBridge 是一个以 Codex 为核心的桥接网关，用来把微信等聊天平台接到同一个 Codex 执行引擎上，并在需要时切换 Codex 内部的后端 Provider 配置。

README 默认使用中文说明。命令、路径、环境变量和产品名保持英文，方便直接复制执行。

## 快速开始

如果你只是想先跑通 `个人微信 + Codex`，按这一段走即可。

前置条件：

- Node.js `>= 24`
- `npm`
- 当前机器已经安装并登录可用的 Codex CLI

```bash
npm install
npm run typecheck
npm test
codex --version
npm run weixin:login
npm run weixin:serve -- --cwd /absolute/path/to/workspace
```

Windows 用户在 PowerShell 里执行同样流程，并使用 Windows 路径：

```powershell
npm install
npm run typecheck
npm test
codex --version
where codex
npm run weixin:login
npm run weixin:serve -- --cwd C:\absolute\path\to\workspace
```

扫码登录微信后，保持 `weixin:serve` 运行，并在微信里发送 `/h` 或 `/status` 做冒烟测试。需要后台常驻时，先完成扫码登录，再安装后台服务；详见 [后台服务](#后台服务)。

## 当前方向

- 第一交付目标是 `个人微信 + Codex`
- 暂停继续扩展 package 侧实验，先把微信主路径打磨稳定
- `packages/codex-gateway` 暂不活跃开发
- `packages/mission-control` 暂不活跃开发
- `packages/codex-native-api` 保留为未来可能继续推进的包，但当前也暂停
- 核心原则：平台只是适配器，Codex 保持执行引擎地位，Codex thread 状态保持事实来源

## 文档

- [核心架构](./docs/architecture/codexbridge-core-architecture.md)
- [Roadmap TODO](./docs/todo/roadmap.md)
- [Codex Native API TODO](./docs/todo/codex-native-api.md)
- [Codex Gateway TODO - 已暂停](./docs/todo/codex-gateway.md)
- [Mission Control TODO - 已暂停](./docs/todo/mission-control.md)
- [Mission Control 架构 - 历史参考](./docs/architecture/mission-control.md)
- [微信 slash command 参考](./docs/usage/weixin-slash-commands.md)

## 目录结构

```text
packages/
src/
  core/
  platforms/
  providers/
  runtime/
  store/
test/
docs/
```

## 当前状态

当前项目启动与演进重点：

1. 以 `个人微信 + Codex` 作为产品中心
2. 在桥接方向更清晰前，避免继续扩展后端/package 工作面
3. 将 `codex-gateway` 和 `mission-control` 视为已暂停工作流
4. 仅保留 `codex-native-api` 作为未来选项，不作为当前主线

当前已经实现的桥接能力：

- 面向微信聊天体验的核心会话路由与 slash commands，包括 `/helps`、`/status`、`/usage`、`/login`、`/stop`、`/review`、`/plan`、`/skills`、`/plugins`、`/automation`、`/weibo`、`/new`、`/uploads`、`/as`、`/log`、`/todo`、`/remind`、`/note`、`/provider`、`/models`、`/model`、`/personality`、`/instructions`、`/fast`、`/threads`、`/search`、`/next`、`/prev`、`/open`、`/peek`、`/rename`、`/permissions`、`/allow`、`/deny`、`/reconnect`、`/retry`、`/restart` 和 `/lang`
- `/open` 会重新绑定当前微信作用域，并立即返回近期对话预览，用户可以用一个命令恢复旧线程
- 基于文件 JSON repository 的持久化桥接状态
- 微信平台适配层：Hermes 兼容 iLink 配置加载、扫码账号状态复用、私聊入站消息标准化、长轮询 client/poller、context-token 持久化、文本切块、出站文本/typing 发送
- Codex profile loader，以及用于共享 thread 执行的初始 Codex app-server client/plugin 路径
- 微信 runtime 会把 poll 事件送入共享 bridge coordinator，并通过微信 transport 发回结果
- OpenAI-compatible Responses adapter，用于接入非 OpenAI Chat Completions Provider，包含 compact fallback、SSE stream 转换、tool-call repair、provider/model capability 规则和 gated live-provider smoke tests

Package 工作流状态：

- `packages/codex-gateway`：已暂停
- `packages/mission-control`：已暂停
- `packages/codex-native-api`：仅保留为未来选项，当前暂停

## OpenAI-Compatible Provider 验证

Live provider 验证是显式 opt-in，默认测试不会消耗 API 额度。

```bash
CODEXBRIDGE_TEST_LIVE_OPENAI_COMPATIBLE=1 pnpm exec tsx --test test/providers/openai_compatible/live_provider_smoke.test.ts
```

支持的 smoke test 环境变量：

```text
DEEPSEEK_API_KEY / DEEPSEEK_BASE_URL / DEEPSEEK_DEFAULT_MODEL
MINIMAX_API_KEY / MINIMAX_BASE_URL / MINIMAX_MODEL
QWEN_API_KEY or DASHSCOPE_API_KEY / QWEN_BASE_URL / QWEN_MODEL
OPENROUTER_API_KEY / OPENROUTER_BASE_URL / OPENROUTER_MODEL
KIMI_API_KEY / KIMI_BASE_URL / KIMI_MODEL
GEMINI_API_KEY / GEMINI_BASE_URL / GEMINI_MODEL
IFLOW_API_KEY / IFLOW_BASE_URL / IFLOW_MODEL
```

本地 OpenAI-compatible adapter 暂未启用 runtime WebSocket，直到 server 侧补齐 upgrade handler。CLIProxyAPI 风格的 WebSocket transcript/tool-call repair 逻辑已经先作为经过测试的模块落地，后续启用 WebSocket 时可以复用这部分稳定核心。

## 微信 Slash Commands

微信桥现在使用面向聊天文本的命令界面，而不是按钮界面。
推荐入口：

下面示例是 UTF-8 中文，可直接复制到微信。如果 Windows 终端显示中文乱码，请用支持 UTF-8 的编辑器或 GitHub 页面查看后再复制。

```text
/helps
/h
/st
/login
/lg
/login list
/review
/rv
/review base main
/plan
/pl
/plan on
/skills
/sk
/skills search 新闻
/skills show 1
/plugins
/pg
/pg search 日记
/pg show 1
/auto
/auto add 每30分钟检查一次系统状态，有变化发送给我
/auto confirm
/auto list
/auto rename 1 晚间部署巡检
/auto del 1
/as 今天修复了 /pg search 日记召回太宽的问题 #CodexBridge
/as 明天上午10点提醒我给王总回电话
/as ok
/as edit 把王总改成李总，时间改成明天上午11点
/log 今天测试微信桥接，发现插件搜索需要更高相关度
/todo 检查服务器磁盘空间
/todo done 1
/remind 每周一早上9点提醒我看项目进度
/note Notion 适合结构化日志，Google Drive 适合导出归档
/helps threads
/stop
/sp
/provider
/pd
/models
/ms
/model
/m
/model 1
/personality
/psn pragmatic
/instructions
/instructions edit
/fast
/fast off
/model gpt-5.4 xhigh
/model high
/threads
/th
/search bridge
/se bridge
/next
/nx
/prev
/pv
/open 2
/o 2
/peek 2
/pk 2
/rename 2 微信桥接排障
/rn 2 微信桥接排障
/model default
/models
/lang
/permissions
/perm
/allow
/al
/allow 1
/allow 2
/deny
/dn
/retry
/rt
```

### `/models` and `/ms`

列出当前 provider profile 可用的模型。

示例：

```text
/models
/ms
```

### `/automation` and `/auto`

创建和管理定时后台任务。任务结果会发回同一个微信聊天。

示例：

```text
/auto
/auto add 每30分钟检查一次系统状态，有变化发送给我
/auto add 每天早上7点调用 news skill 给我发送到微信
/auto add 工作日晚上6点检查部署状态，异常时通知我
/auto add 每天早上8点、中午13点、下午17点半，把待办事项整理后发到微信
/auto confirm
/auto edit 只把时间改成每小时，任务内容不变
/auto cancel
/weibo
/weibo top 10
/auto add 每5分钟把微博热搜前10条发给我
/auto list
/auto show 1
/auto pause 1
/auto resume 1
/auto rename 1 晚间部署巡检
/auto delete 1
/auto del 1
```

### `/as`, `/log`, `/todo`, `/remind`, and `/note`

微信里的个人助理记录入口。`/as` 是日志、待办、提醒和笔记的统一自然语言入口：它会让 Codex 判断这条消息是在创建新记录，还是在管理已有记录；本地关键词规则只是 provider 不可用时的保守 fallback。需要强制指定类型时，可以继续使用 `/log`、`/todo`、`/remind` 和 `/note`。

示例：

```text
/as 今天修复了 /pg search 日记召回太宽的问题 #CodexBridge
/as 明天上午10点提醒我给王总回电话
/as ok
/as 给王总回电话这件事已经完成了
/as ok
/as 修马桶发票已经拿回来了
/as edit 备注：还差医药发票不确定
/as ok
/log 今天测试微信桥接，发现插件搜索需要更高相关度
/todo 检查服务器磁盘空间
/todo done 1
/remind 每周一早上9点提醒我看项目进度
/note Notion 适合结构化日志，Google Drive 适合导出归档
```

`/as` 也可以用自然语言管理已有记录。Codex 会先把消息路由为 create、update、complete、cancel 或 archive。只有当消息明确指向同一个具体事项时，才会命中已有记录；否则会创建新的 log/todo/reminder/note。对已有记录的修改会先显示为待确认草案，只有发送 `/as ok` 后才写入。可以用 `/as edit <修改说明>` 继续调整待确认草案，也可以用 `/as cancel` 放弃。

对于自然语言更新，桥接层会优先使用一个短生命周期的 Codex app-server rewrite thread，让宿主 Codex 订阅能力处理“原始记录 + 修改说明”的合并。基于 API key 的 Agents SDK normalization 只在 Codex normalization 不可用时作为 fallback；本地规则是最后 fallback。

`/up` 可以先暂存文件。如果最后一条消息是 `/as`、`/log`、`/todo`、`/remind` 或 `/note`，暂存文件会归档到对应助理记录的 `~/.codexbridge/assistant/attachments/YYYY/MM/DD/<recordId>/` 下；结构化记录存储在 `~/.codexbridge/runtime/assistant_records.json`。

边界：`/remind` 只做提醒，`/todo` 跟踪用户自己负责的工作，`/auto` 运行定时系统任务。

### `/plan` and `/pl`

查看或切换当前会话后续 turn 的协作模式。

示例：

```text
/plan
/pl
/plan on
/plan off
```

`/plan on` 会让当前桥接会话后续 turn 使用原生 `plan` 模式。`/plan off` 恢复原生 `default` 协作模式。这是模式切换，不是审批流程。

OpenAI-compatible runtime adapter：

- CodexBridge 可以通过本地 Responses adapter 暴露非 OpenAI provider，而 Codex app-server 仍然访问 Responses 形态的 endpoint。
- adapter 已处理 `/responses/compact`、Chat Completions 转换、stream error mapping、CLIProxyAPI 顶层 stream error chunks、stream read failure framing、可配置的 transient upstream retry、Gemini 系 `usageMetadata` 等 usage fallback、provider/model thinking policy、CLIProxyAPI 风格 payload 兼容（`default`、`default-raw`/`defaultRaw`、`override`、`override-raw`/`overrideRaw`、`filter`、`root`、protocol/model matching）、多模态输入能力标记和模型能力元数据。
- DeepSeek、MiniMax、Qwen、OpenRouter、Kimi、Gemini 和 iFlow 都作为 `providerKind: openai-compatible` 加载；它们只通过环境变量和 capability preset 区分，不需要单独 provider plugin class。
- 模型能力 catalog 采用和 CLIProxyAPI 相同的方向：模型差异作为数据表达（`thinking`、`payload`、tool support、多模态支持、token caps），executor 保持通用。
- 当前内置 catalog 覆盖 Codex-style routing 使用的 CLIProxyAPI 模型家族：Codex、DeepSeek、MiniMax、Qwen、iFlow、Kimi、OpenRouter、Gemini/AI Studio/Vertex、Claude 和 Antigravity。`*_MODEL_CATALOG_PATH` 也可以指向 CLIProxyAPI `models.json` 形态的 catalog object；CodexBridge 会 flatten 并把模型 token/thinking 元数据合并到 runtime capabilities。CLIProxyAPI 的原生 auth/header 系统不会复制到这个 adapter；部署侧凭据请使用 provider 环境变量或自定义 `CODEX_COMPAT_*` profile。
- Auth pool、proxy rotation 和自定义 provider header 管理仍属于部署层职责，刻意和通用 OpenAI-compatible adapter 分离。

Runtime provider examples:

```bash
DEEPSEEK_API_KEY=...
DEEPSEEK_DEFAULT_MODEL=deepseek-v4-flash

MINIMAX_API_KEY=...
MINIMAX_BASE_URL=https://api.minimaxi.com/v1
MINIMAX_MODEL=MiniMax-M2.7
MINIMAX_REQUEST_RETRY=2
MINIMAX_RETRY_STATUSES=429,503

KIMI_API_KEY=...
KIMI_BASE_URL=https://api.kimi.com/coding
KIMI_MODEL=kimi-k2

GEMINI_API_KEY=...
GEMINI_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai
GEMINI_MODEL=gemini-2.5-pro

IFLOW_API_KEY=...
IFLOW_BASE_URL=https://apis.iflow.cn/v1
IFLOW_MODEL=qwen3-coder-plus

CODEX_COMPAT_PROVIDER_ID=custom
CODEX_COMPAT_API_KEY=...
CODEX_COMPAT_BASE_URL=https://provider.example/v1
CODEX_COMPAT_DEFAULT_MODEL=example-model
CODEX_COMPAT_CAPABILITIES=default # or deepseek/minimax/qwen/kimi/gemini/iflow/openrouter
CODEX_COMPAT_REQUEST_RETRY=2
```

### `/model` and `/m`

查看或切换后续 turn 使用的模型。

示例：

```text
/model
/m
/model default
/model high
/model 1
/model 1 xhigh
/model gpt-5.4 xhigh
/model gpt-5.4
```

所有 slash command 都支持命令级帮助参数：

```text
/threads -h
/open --help
/permissions -helps
```

建议用法：

- 用 `/helps` 发现可用命令
- 用 `/login` 和 `/login list` 管理宿主机 Codex 账号池，再用 `/login <index>` 切换账号
- 需要原生 Codex code review 且不想改变当前 thread 绑定时，用 `/review`、`/review base <branch>` 或 `/review commit <sha>`
- 希望当前会话后续 turn 优先规划时，用 `/plan on`；恢复默认协作模式时，用 `/plan off`
- 用 `/skills` 查看 Codex 在当前项目里能看到哪些 skill；用 `/skills search <keyword>` 搜索相关项；启用或禁用前用 `/skills show <index>` 理解用途
- 新建自动化时优先用自然语言 `/auto add ...`，桥接层会先生成计划草案，再用 `/auto confirm` 创建任务
- 在微信里用 `/threads` 和数字序号操作线程，避免复制原始 thread id
- 用 `/personality` 控制当前作用域后续回复风格
- 用 `/instructions` 管理当前 Codex `AGENTS.md` 自定义指令文件
- 用 `/lang zh-CN` 或 `/lang en` 切换当前作用域回复语言；默认是 `zh-CN`
- 当 Codex 在 turn 中请求审批时，用 `/allow 1` 或 `/allow 2` 批准，用 `/deny` 拒绝
- turn 被中断后用 `/retry`；它会先刷新当前 Codex session，再在同一个 thread 中重跑上一条请求
- 需要精确用法和示例时，用 `/helps <command>`

完整命令参考见 [docs/usage/weixin-slash-commands.md](./docs/usage/weixin-slash-commands.md)。

## 验证

```bash
npm install
npm run typecheck
npm test
```

验证套件应在 Linux 和 Windows 上通过。

`npm test` 是隔离后的默认测试入口。它会在启动 `node --test` 前清理 `CODEXBRIDGE_AGENT_*`、`OPENAI_*`、`MINIMAX_API_KEY` 等 live agent provider 变量，所以即使宿主 shell、CI runner 或 service manager 暴露了真实模型凭据，单元测试和集成测试也能保持确定性。

如果你明确想保留 live agent 凭据并验证真实外部 agent 路径，再使用这个显式 opt-in 脚本：

```bash
npm run test:live-agent
```

请把 `test:live-agent` 和主测试套件、首次部署 checklist 分开。它用于配置好凭据后的真实 provider 验证，不属于默认 `npm test` gate。

## 部署快速开始

### 通用前置条件

- Node.js `>= 24`
- `npm`
- 宿主机上可用且已登录的 Codex CLI

克隆后建议先检查：

```bash
npm install
npm run typecheck
npm test
codex --version
```

如果还没有安装 Codex CLI，先安装：

```bash
npm install -g @openai/codex@latest --include=optional
codex --version
```

如果 `codex --version` 仍然失败，请先修复 Codex CLI，再尝试 `weixin:login` 或 `weixin:serve`。

### Linux

```bash
npm install
npm run typecheck
npm test
codex --version
npm run weixin:login
npm run weixin:serve -- --cwd /absolute/path/to/workspace
```

长期运行时，建议使用下面的 service-manager 流程，而不是一直开着终端窗口。

### Windows 首次启动

在仓库根目录打开 PowerShell 并运行：

```powershell
npm install
npm run typecheck
npm test
codex --version
where codex
npm run weixin:login
npm run weixin:serve -- --cwd C:\absolute\path\to\workspace
```

如果宿主机 `PATH` 上存在多个 Codex shim，启动桥接前可以显式设置真实 native binary：

```powershell
$env:CODEX_REAL_BIN = (Get-Command codex.exe).Source
npm run weixin:serve -- --cwd C:\absolute\path\to\workspace
```

可选调试开关：

```powershell
$env:CODEXBRIDGE_DEBUG_WEIXIN = '1'
```

### 首次 Windows 部署后已加固的点

第一次 Windows bring-up 暴露了四个和平台相关的问题：

1. 命令发现：provider config 原来假设 Unix 风格命令查找。现在 loader 会直接解析 Windows executable，并在同时存在 wrapper 和 native binary 时优先使用 `codex.exe` / `.com`。
2. Windows 启动 wrapper：如果宿主机只暴露 `codex.cmd` 或 `codex.bat`，桥接层现在会通过 Windows shell command line 启动 wrapper，不再在 `spawn(...)` 阶段失败。
3. 启动诊断：如果无法启动 Codex，现在会直接提示 `CODEX_REAL_BIN` / `codex.exe` / `codex.cmd`，而不是只留下原始 `spawn codex ENOENT`。
4. Thread materialization：从 Codex session storage 读取时遇到短暂 `empty session file`，现在会自动重试，不再直接视为 fatal turn failure。

### Runtime 默认路径

- 状态目录：`~/.codexbridge`
- 微信账号文件：`~/.codexbridge/weixin/accounts/`
- Serve lock 文件：`~/.codexbridge/runtime/weixin-serve.lock`
- 默认 Codex auth 路径：`~/.codex/auth.json`
- 默认 Codex instructions 路径：`~/.codex/AGENTS.md`

### 微信 Runtime Checklist

绑定微信账号只是登录步骤。要让微信持续收到回复，`weixin:serve` loop 必须保持运行。

标准顺序：

1. `npm run weixin:login`
2. 确认账号文件已写入 `~/.codexbridge/weixin/accounts/`
3. 启动 `npm run weixin:serve`
4. 在微信里发送 `/h` 或 `/status` 做冒烟测试
5. 保持进程运行，或安装下面的平台服务管理器

### 排障

- 微信绑定后没有回复：确认 `weixin:serve` 仍在运行。扫码登录本身不会自动启动后台 worker。
- `spawn codex ENOENT` 或桥接层无法启动 Codex：先运行 `codex --version`。Windows 上必要时把 `CODEX_REAL_BIN` 设置为 `codex.exe` 或 `codex.cmd` 的完整路径。
- turn 已开始但没有最终回复：使用 `CODEXBRIDGE_DEBUG_WEIXIN=1` 查看 debug log。当前版本会自动重试短暂 `empty session file` 读取。
- 需要检查 runtime 状态：账号状态在 `~/.codexbridge/weixin/accounts/`，当前 serve lock 在 `~/.codexbridge/runtime/weixin-serve.lock`。

## 媒体工具

图片归一化和视频缩略图生成使用项目依赖管理的 `ffmpeg` / `ffprobe`，来源是 `ffmpeg-static` 和 `ffprobe-static`。

解析顺序：

- `CODEXBRIDGE_FFMPEG_PATH` / `CODEXBRIDGE_FFPROBE_PATH`
- `FFMPEG_PATH` / `FFPROBE_PATH`
- 项目依赖中自带的 binary
- 系统 `PATH` fallback

这样在常见场景下不需要手动全局安装 `ffmpeg`，也能在 Linux、macOS 和 Windows 间保持图片/视频处理可移植。

## 微信登录

```bash
npm run weixin:login
```

运行微信桥接 loop：

```bash
npm run weixin:serve
```

默认情况下，桥接层会把启动 `weixin:serve` 的目录作为新会话的共享工作目录。你可以用 `--cwd` 或 `CODEXBRIDGE_DEFAULT_CWD` 覆盖，也可以在微信里用 `/new /absolute/path/to/project` 为某个聊天重新绑定目录。

## i18n

桥接层现在使用统一的 i18n 层处理用户可见 runtime 文本。

- 支持的语言：
  - `zh-CN`
  - `en`
- 默认语言：`zh-CN`
- 进程级覆盖：
  - `CODEXBRIDGE_LOCALE=zh-CN`
  - `CODEXBRIDGE_LOCALE=en`

示例：

```bash
CODEXBRIDGE_LOCALE=en npm run weixin:serve
```

当前语言设置会影响：

- slash-command 回复
- 微信 runtime 失败消息
- CLI login / serve 提示
- bridge restart 完成通知

## 后台服务

桥接主循环是 `weixin:serve`。如果需要无人值守运行，请把它注册到宿主机 service manager，让它在登录/启动后自动运行，并在崩溃后重启。

重要限制：

- service manager 只能在电脑开机且操作系统运行时保持 CodexBridge 存活。
- 电脑关机、睡眠或断网时无法接收消息。
- 桌面操作系统上的用户级服务依赖用户登录/session 模型。Linux `linger` 和 macOS `launchd` 可以不打开终端运行；下面的 Windows Task Scheduler 默认在用户登录后运行。

### Linux systemd 用户服务

在 Linux 上安装并启动用户服务：

```bash
bash ./scripts/service/install-systemd-user.sh
```

常用后续命令：

```bash
bash ./scripts/service/status-systemd-user.sh
bash ./scripts/service/restart-systemd-user.sh
bash ./scripts/service/logs-systemd-user.sh
bash ./scripts/service/logs-systemd-user.sh --follow
```

安装器使用 `Restart=always`，并会尝试启用 `loginctl linger`，让用户服务在注销后也能继续运行。如果无法自动启用 linger，请手动运行：

```bash
loginctl enable-linger "$USER"
```

安装器会把用户级环境文件写到：

```text
~/.config/codexbridge/weixin.service.env
```

这个文件是调整以下配置的稳定位置：

- `WEIXIN_ACCOUNT_ID`
- `CODEX_DEFAULT_PROVIDER_PROFILE_ID`
- optional OpenAI-compatible provider keys such as `DEEPSEEK_*`, `MINIMAX_*`, `QWEN_*`, `OPENROUTER_*`, or `CODEX_COMPAT_*`
- `CODEXBRIDGE_DEBUG_WEIXIN`

### Windows 计划任务

安装并启动隐藏的用户级计划任务：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\service\install-windows-task.ps1
```

常用后续命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\service\status-windows-task.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\service\restart-windows-task.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\service\logs-windows-task.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\service\logs-windows-task.ps1 -Follow
```

如果希望右下角通知区域显示一个托盘控制图标，可以在扫码登录并安装桥接计划任务后运行：

```powershell
.\install-weixin-tray-after-login.cmd
```

托盘图标会随当前用户登录自动启动。右键菜单可查看状态、启动/停止/重启 `CodexBridge-Weixin` 计划任务、打开日志目录或实时跟随日志；双击图标会打开实时日志窗口。托盘图标只是控制器，真正的微信桥仍由 `CodexBridge-Weixin` 计划任务运行。

安装器会把环境文件写到：

```text
%APPDATA%\codexbridge\weixin.service.env
```

日志写在：

```text
%USERPROFILE%\.codexbridge\logs\
```

如果需要任务在机器启动时运行，而不是用户登录后运行，可以传入 `-AtStartup`。这个模式可能需要管理员权限，并且仍要确保用户环境能访问 Codex auth 文件。

### macOS launchd 用户服务

安装并启动 launch agent：

```bash
bash ./scripts/service/install-launchd-user.sh
```

常用后续命令：

```bash
bash ./scripts/service/status-launchd-user.sh
bash ./scripts/service/restart-launchd-user.sh
bash ./scripts/service/logs-launchd-user.sh
bash ./scripts/service/logs-launchd-user.sh --follow
```

安装器会写入：

```text
~/Library/LaunchAgents/com.ganxing.codexbridge-weixin.plist
~/.config/codexbridge/weixin.service.env
~/.codexbridge/logs/
```

### 服务 Runner

Windows 和 macOS 使用 `scripts/service/run-weixin-service.mjs` 作为小型 supervisor。它会加载 service env 文件，并启动：

```bash
node --import tsx src/cli.ts weixin serve
```

如果进程意外退出，它会自动重启。Linux 则依赖 systemd 原生的 `Restart=always`。

常用环境/配置值：

- `--base-url`
- `--cwd`
- `--state-dir`
- `--bot-type`
- `--timeout-sec`

登录命令会获取二维码，把二维码图片保存到 `~/.codexbridge/weixin/login/`，打印文件路径，并等待扫码确认。凭据随后会存入 `~/.codexbridge/weixin/accounts/`。Runtime 脚本现在直接执行 `tsx src/cli.ts` 和 `tsx src/index.ts`。
