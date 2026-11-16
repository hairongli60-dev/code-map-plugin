# code-map — 项目代码地图

给 Claude Code 用的一个小插件，解决两件具体的事：

1. **代码找不到** —— agent 跑完任务生成一堆脚本，散在临时目录里，事后不知道写了什么
2. **看不到代码内容** —— 没有一张"这个项目有哪些代码、各自干什么"的地图

## 装什么

| 组件 | 作用 |
|---|---|
| `code-map` skill | 生成/增量更新 `CODE_MAP.md`：入口、用途、依赖、孤儿、未跟踪文件 |
| `guard-temp-write` hook | 在写入时拦截"把代码文件写进 `%TEMP%` / `/tmp`"的行为，把它们赶回项目目录 |

两者互补：hook 保证代码**写对地方**，skill 保证写下来的代码**看得懂、查得到**。

## 安装

```
/plugin marketplace add hairongli60-dev/code-map-plugin
/plugin install code-map@ai-toolkit
```

装完新开一个会话，hook 自动生效（首次会弹一次信任确认，这是 Claude Code 的机制）。

## 用法

对 AI 说：

- 「更新代码地图」→ 扫描项目，生成或增量更新 `CODE_MAP.md`
- 「这个项目有哪些脚本」→ 同上，只回答不落盘
- 「有没有没人用的代码」→ 只跑孤儿判定

日常不需要维护什么。新代码只要在项目里，`git status` 天然把它带进清单，
下次更新地图时补上描述即可。

## 增量是怎么算的

| 谁 | 保证什么 | 成本 |
|---|---|---|
| `git ls-files` / `git status` | 新文件一定出现在清单里 | 零 |
| skill（按需运行） | 文件干什么、谁引用谁、哪些该删 | 一次几 k token |
| hook | 脚本不会被写到项目外 | 零 |

**地图不是后台实时更新的**——它靠 `git` 保证不漏，靠按需运行保证可读。

## hook 的判定规则

- 在项目目录内写 → 放行
- 在临时目录（`/tmp`、`%TEMP%`、`AppData/Local/Temp`）里写**代码文件** → 阻止，并提示改写到 `<项目>/scripts/`
- 其他位置、非代码文件 → 放行

只拦代码扩展名（`.py .m .R .jl .js .ts .sh .ps1 .c .go .rs .java .sql .ipynb`），
文档、数据、图片不受影响。

## 仓库结构

```
.claude-plugin/marketplace.json          # 市场清单
plugins/code-map/
├── .claude-plugin/plugin.json           # 插件清单
├── skills/code-map/
│   ├── SKILL.md
│   └── scripts/scan.sh                  # 紧凑扫描器
└── hooks/
    ├── hooks.json
    └── scripts/guard-temp-write.sh
```

## 发布到 GitHub

```bash
cd code-map-plugin
git init -b main
git add .
git commit -m "初始版本：code-map 插件"
gh repo create code-map-plugin --public --source=. --push
```

想改行为：改 `skills/code-map/SKILL.md`（Claude 怎么理解任务）或
`hooks/scripts/guard-temp-write.sh`（拦截规则），
然后升 `plugins/code-map/.claude-plugin/plugin.json` 的 `version`，
再 `git push`，用户侧 `/plugin update` 才会拿到。

## Windows 说明

hook 用 `bash` 执行，需要 Git Bash 在 PATH 上（装了 Git for Windows 就有）。
路径比较前统一把 `\` 转成 `/`、转小写、合并重复斜杠，避免 `I:\AI` 和 `i:/ai` 认不出来。

## 许可

MIT
