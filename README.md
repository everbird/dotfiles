# Dotfiles

Personal dotfiles for macOS and Linux (Ubuntu), designed around **simplicity, zero framework bloat, and native cross-platform configuration**.

## Structure

```text
dotfiles/
├── install.sh                 # Zero-dependency symlink & bootstrap manager
├── Makefile                   # Shortcuts: make, make link, make bootstrap, make status
├── zsh/
│   ├── .zshenv                # Disables redundant system-wide compinit on Ubuntu/Debian
│   ├── .zshrc                 # Fast, standalone Zsh config (Powerlevel10k + 4 core plugins)
│   └── .p10k.zsh              # Powerlevel10k prompt configuration
├── git/
│   ├── .gitconfig             # Unified Git config (supports ~/.gitconfig.local & work includeIf)
│   └── .config/git/ignore     # Global gitignore
├── tmux/
│   └── .tmux.conf             # Tmux config (C-q prefix, OSC 52 clipboard, TPM)
├── doom/
│   └── .doom.d/               # Doom Emacs configuration (init.el, config.el, packages.el)
├── editorconfig/
│   └── .editorconfig          # Universal EditorConfig rules
├── gpg/
│   ├── gpg-agent.conf.linux   # Linux pinentry & cache TTL config
│   └── gpg-agent.conf.macos   # macOS pinentry config
└── iterm2/                    # macOS iTerm2 color schemes & profiles
```

## Quick Start

```bash
# Install external plugins (Zsh plugins, everbird-dotvim, TPM) & link all dotfiles
make

# Only update symlinks
make link

# Check symlink and plugin health
make status
```

## Local & Work Overrides

Instead of duplicating directories per OS or environment, use local untracked override files:

- **Zsh**: Create `~/.zshrc.local` for machine-specific environment variables or private aliases.
- **Git**:
  - Create `~/.gitconfig.local` for machine-specific Git settings.
  - Repositories under `~/workspace/work/` automatically include `~/.gitconfig.work` via `includeIf`.
