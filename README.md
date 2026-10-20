# Dotfiles

个人跨平台（macOS / Linux）配置文件仓库，遵循 **实用、简单、清晰、零框架冗余** 原则。

- **所见即所得**：通过软链（Symlink）直接映射 `$HOME`，修改 `~/.zshrc` 即直接修改仓库文件。
- **零外部管理依赖**：不依赖 `stow`、`chezmoi` 或 Git Submodule，内置 [`install.sh`](./install.sh) 一键完成依赖拉取、冲突自动备份与软链维护。
- **极速 Zsh（~50ms 启动）**：基于原生 Zsh 配置 + 直连 `powerlevel10k` 与 4 个核心插件，告别 `oh-my-zsh` / `zplug` 启动卡顿。

---

## 一、 目录结构

```text
dotfiles/
├── install.sh                 # 零依赖安装与管理脚本（顶部声明 DOTFILE_LINKS 与 ZSH_PLUGINS）
├── Makefile                   # 常用命令入口（make, make link, make bootstrap, make status）
├── zsh/
│   ├── .zshenv                # 环境变量与禁用 Ubuntu 全局重复 compinit
│   ├── .zshrc                 # 跨平台 Zsh 主配置（原生手感 + 插件自动按需加载）
│   └── .p10k.zsh              # Powerlevel10k 提示符样式配置
├── git/
│   ├── .gitconfig             # 统一 Git 配置（支持本地与工作目录条件覆盖）
│   └── .config/git/ignore     # 全局 gitignore
├── tmux/
│   └── .tmux.conf             # Tmux 配置（C-q 前缀、OSC 52 剪贴板同步、TPM 插件）
├── doom/
│   └── .doom.d/               # Doom Emacs 配置（init.el, config.el, packages.el, custom.el）
├── editorconfig/
│   └── .editorconfig          # 通用编辑器缩进与编码规范
├── gpg/
│   ├── gpg-agent.conf.linux   # Linux GPG Agent 配置
│   └── gpg-agent.conf.macos   # macOS GPG Agent 配置
└── iterm2/                    # macOS iTerm2 配色与 Profile 备份
```

---

## 二、 日常使用命令

在仓库根目录下直接通过 `make` 操作：

```bash
# 1. 一键完整安装（新机器初始化推荐：自动拉取外部插件 + 创建全部软链）
make

# 2. 仅更新软链（新增或调整配置文件路径后执行，已有同名非软链文件会自动备份为 *.bak.<时间戳>）
make link

# 3. 仅安装/检查外部插件框架（Zsh 插件、everbird-dotvim、Tmux TPM）
make bootstrap

# 4. 检查所有软链与外部插件状态（OK / DRIFTED / MISSING）
make status

# 5. 卸载所有指向本仓库的软链
make unlink
```

---

## 三、 如何添加新的配置

所有软链映射都集中在 [`install.sh`](./install.sh) 顶部的 `DOTFILE_LINKS` 数组中，添加新配置只需 **2 步**：

### 1. 纳管普通配置文件（以 `htop` 为例）
1. 将配置文件放入仓库对应模块目录：
   ```bash
   mkdir -p htop/.config/htop
   mv ~/.config/htop/htoprc htop/.config/htop/htoprc
   ```
2. 在 [`install.sh`](./install.sh) 顶部的 `DOTFILE_LINKS` 数组中添加一行（格式为 `"仓库相对路径:HOME相对路径"`）：
   ```bash
   DOTFILE_LINKS=(
     "zsh/.zshenv:.zshenv"
     "zsh/.zshrc:.zshrc"
     ...
     "htop/.config/htop/htoprc:.config/htop/htoprc"
   )
   ```
3. 执行 `make link` 即可生效（`make status` 和 `make unlink` 也会自动纳管该文件）。

### 2. 纳管区分 macOS / Linux 的配置文件
如果某个配置文件在 macOS 和 Linux 下内容不同，放到 [`install.sh`](./install.sh) 顶部的系统判断分支即可：
```bash
case "$(uname -s)" in
  Darwin*) DOTFILE_LINKS+=("gpg/gpg-agent.conf.macos:.gnupg/gpg-agent.conf") ;;
  Linux*)  DOTFILE_LINKS+=("gpg/gpg-agent.conf.linux:.gnupg/gpg-agent.conf") ;;
esac
```

### 3. 添加新的 Zsh 插件
1. 在 [`install.sh`](./install.sh) 顶部的 `ZSH_PLUGINS` 数组中加入 GitHub `"作者/仓库名"`；
2. 在 [`zsh/.zshrc`](./zsh/.zshrc) 的第 4 节中加入对应的 `_zsh_ensure_plugin "作者/仓库名"` 和 `source` 语句。

---

## 四、 本机私有配置与多环境隔离（不入库）

为了避免把机器私有路径、Token 或公司内网配置提交到公开仓库，支持以下本地覆盖文件（均已被 `.gitignore` 忽略）：

- **Zsh 本机私有配置 (`~/.zshrc.local`)**：
  [`zsh/.zshrc`](./zsh/.zshrc) 末尾会自动加载 `~/.zshrc.local`。本机特有的环境变量、内网 SSH 别名等可直接写在该文件中。
- **Git 本机与工作目录配置**：
  - **`~/.gitconfig.local`**：存放当前机器私有的 Git 配置。
  - **`~/.gitconfig.work`**：当 Git 仓库位于 `~/workspace/work/` 目录下时，[`git/.gitconfig`](./git/.gitconfig) 会通过 `includeIf` 自动加载 `~/.gitconfig.work`（可用于配置工作邮箱和独立签名设置）。
