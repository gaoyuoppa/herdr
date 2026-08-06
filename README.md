# herdr

<p align="center">
  <img src="assets/logo.png" alt="herdr" width="100" />
</p>

<p align="center">
  <a href="#本-fork-说明">本 Fork</a> · <a href="#安装">安装</a> · <a href="https://herdr.dev/zh-cn/docs/quick-start/">快速开始</a> · <a href="https://herdr.dev/zh-cn/docs/">文档</a> · <a href="#赞助">赞助</a>
</p>

<p align="center">
  简体中文 · <a href="https://github.com/herdrdev/herdr#readme">上游英文说明</a>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache--2.0-666666?labelColor=333333" alt="Apache 2.0 许可证" /></a>
  <a href="https://github.com/herdrdev/herdr/releases"><img src="https://img.shields.io/github/downloads/herdrdev/herdr/total?labelColor=333333&color=666666" alt="GitHub Release 总下载量" /></a>
  <a href="https://github.com/herdrdev/herdr/stargazers"><img src="https://img.shields.io/github/stars/herdrdev/herdr?labelColor=333333&color=666666&logo=github" alt="GitHub Stars" /></a>
  <a href="https://github.com/herdrdev/herdr/releases/latest"><img src="https://img.shields.io/github/v/release/herdrdev/herdr?label=release&labelColor=333333&color=666666" alt="最新稳定版" /></a>
  <a href="https://formulae.brew.sh/formula/herdr"><img src="https://img.shields.io/homebrew/v/herdr?label=homebrew&labelColor=333333&color=666666" alt="Homebrew 版本" /></a>
  <a href="https://x.com/herdrdev"><img src="https://img.shields.io/badge/follow-%40herdrdev-000000?logo=x&logoColor=white" alt="在 X 上关注 @herdrdev" /></a>
</p>

---

## 本 Fork 说明

这是由 `gaoyuoppa` 维护的 Herdr 定制 Fork。默认分支 `deploy/zh-with-perf` 在官方代码基础上保留中文化、性能优化及本地功能；`master` 仅用于镜像官方上游。

> [!IMPORTANT]
> 克隆或 Fork 本项目不会获得维护者的部署密钥，也不会连接或操作维护者的服务器。GitHub Actions Secrets 不会随 Fork 复制，原仓库的部署工作流也只有具备写权限的人才能手动触发。维护自己的 Fork 时，请配置你自己的服务器变量和 Secrets，切勿把密钥提交到代码中。

自动同步、构建和部署机制详见 [Fork 自动化说明](.github/FORK_AUTOMATION.md)。

---

https://github.com/user-attachments/assets/043ec09f-4bdd-41d5-aee0-8fda6b83e267

**编码智能体长期运行的终端运行时。**

- **始终运行**——Herdr 是后台服务器，终端会话驻留其中；合盖、断网或重启后，智能体和会话仍可恢复，并可从任意终端或通过 SSH 重新连接。
- **无需再寻找卡住的智能体**——每个窗格都会标记为工作中、阻塞或空闲；智能体停下并需要回答时，Herdr 会明确提示。
- **智能体原生**——CLI 和 Socket API 都可由智能体直接驱动，用于创建窗格、相互发送提示并等待另一个智能体真正阻塞。[智能体技能 →](https://herdr.dev/zh-cn/docs/agent-skill/)
- **兼容现有智能体**——Claude Code、Codex、Cursor、OpenCode、Grok 等均可直接运行；Herdr 不包装或替代它们，只管理其终端。
- **键盘和鼠标都是一等公民**——既支持 tmux 风格前缀键，也支持点击、拖动和分割，可按场景自由选择。
- **插件系统**——扩展窗格和工作流。[浏览插件市场 →](https://herdr.dev/plugins/)
- **单个 Rust 二进制，不依赖 Electron**——直接运行在你已经使用的终端里。

---

## 安装

### 使用本 Fork 定制版

Linux 从默认定制分支构建：

```bash
git clone --branch deploy/zh-with-perf https://github.com/gaoyuoppa/herdr.git
cd herdr
cargo build --release --locked
```

Windows x64 推荐直接下载 **Sync upstream, build, and deploy** 工作流中的
`herdr-windows-x86_64-<commit>` 构建产物。解压后的目录包含本地化
`herdr.exe`、经过哈希和 Microsoft 签名验证的 ConPTY 运行库及第三方声明，整个目录可直接移动使用。

```powershell
# 在解压目录中启动；目录加入 PATH 后可省略 .exe 和相对路径
.\herdr.exe
herdr
```

Herdr 是终端程序，不是桌面 GUI；Windows 的程序文件名必须是 `herdr.exe`，但并不要求双击，通常在 PowerShell、CMD 或 Windows Terminal 中通过 `herdr` 命令启动。若自行编译：

```powershell
git clone --branch deploy/zh-with-perf https://github.com/gaoyuoppa/herdr.git
Set-Location herdr
cargo build --release --locked --target x86_64-pc-windows-msvc
```

项目当前使用 Rust 1.96.1 和 Zig 0.15.2。自动化生成
`x86_64-unknown-linux-musl` 静态二进制，以及
`x86_64-pc-windows-msvc` 的 Release ConPTY 便携包；Windows 包不会自动部署到 Linux 服务器。

中文资源已直接编译进 Linux 和 Windows 程序。Windows 在
`$env:APPDATA\herdr\config.toml`（通常是
`%APPDATA%\herdr\config.toml`）中启用中文：

```toml
[ui]
language = "zh"
```

### 使用官方稳定版

以下命令安装的是 `herdrdev/herdr` 官方版本，不包含本 Fork 的定制修改：

```bash
curl -fsSL https://herdr.dev/install.sh | sh
```

也可以使用 `brew install herdr`、`mise use -g herdr`，或安装 Windows 测试版：

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
```

官方预编译文件见 [herdrdev/herdr Releases](https://github.com/herdrdev/herdr/releases)。

安装后，在工作目录中启动：

```bash
herdr
```

运行智能体并按需分割窗格。`ctrl+b q` 用于分离，重新执行 `herdr` 即可连接回来。[快速开始 →](https://herdr.dev/zh-cn/docs/quick-start/)

## 文档

官方中文文档位于 [herdr.dev/zh-cn/docs](https://herdr.dev/zh-cn/docs/)： [快速开始](https://herdr.dev/zh-cn/docs/quick-start/) · [核心概念](https://herdr.dev/zh-cn/docs/concepts/) · [支持的智能体](https://herdr.dev/zh-cn/docs/agents/) · [键盘操作](https://herdr.dev/zh-cn/docs/keyboard/) · [配置](https://herdr.dev/zh-cn/docs/configuration/) · [会话状态](https://herdr.dev/zh-cn/docs/session-state/) · [远程访问](https://herdr.dev/zh-cn/docs/persistence-remote/) · [集成](https://herdr.dev/zh-cn/docs/integrations/) · [插件](https://herdr.dev/zh-cn/docs/plugins/) · [Socket API](https://herdr.dev/zh-cn/docs/socket-api/)

## 赞助

Herdr 以全职、开放的方式开发。赞助将直接用于项目开发、稳定性以及真正的智能体运行时。

### 金牌赞助

<a href="https://terminaltrove.com/"><img src="assets/sponsors/terminal-trove.png" alt="Terminal Trove" width="200" /></a>

[**→ 成为赞助者**](https://github.com/sponsors/ogulcancelik) · 企业合作：hey@herdr.dev · 赞助档位见 [SPONSORS.md](./SPONSORS.md)。谢谢 🐑

## 智能体须知

如果你是协助本仓库的 AI 智能体，请在修改代码前阅读 [`AGENTS.md`](./AGENTS.md)，在创建 Issue 或 PR 前阅读 [`CONTRIBUTING.md`](./CONTRIBUTING.md)。

## 开发

```bash
git clone --branch deploy/zh-with-perf https://github.com/gaoyuoppa/herdr.git
cd herdr
cargo build --release

just test        # 单元测试
just check       # 格式检查、测试和维护性检查
```

## 许可证

Herdr 基于 [Apache License 2.0](LICENSE) 发布。
