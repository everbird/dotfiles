#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"
BACKUP_SUFFIX="bak.$(date +%Y%m%d%H%M%S)"
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# ==============================================================================
# 1. Declarative Dotfiles Map
#    Format: "repo_relative_path:home_relative_path"
#    To manage a new dotfile in the future, just add one line to DOTFILE_LINKS!
# ==============================================================================
DOTFILE_LINKS=(
  "zsh/.zshenv:.zshenv"
  "zsh/.zshrc:.zshrc"
  "zsh/.p10k.zsh:.p10k.zsh"
  "git/.gitconfig:.gitconfig"
  "git/.config/git/ignore:.config/git/ignore"
  "tmux/.tmux.conf:.tmux.conf"
  "editorconfig/.editorconfig:.editorconfig"
  "doom/.doom.d/init.el:.doom.d/init.el"
  "doom/.doom.d/config.el:.doom.d/config.el"
  "doom/.doom.d/packages.el:.doom.d/packages.el"
  "doom/.doom.d/custom.el:.doom.d/custom.el"
)

# OS-specific links added automatically
case "$(uname -s)" in
  Darwin*) DOTFILE_LINKS+=("gpg/gpg-agent.conf.macos:.gnupg/gpg-agent.conf") ;;
  Linux*)  DOTFILE_LINKS+=("gpg/gpg-agent.conf.linux:.gnupg/gpg-agent.conf") ;;
esac

# External Zsh plugins (GitHub owner/repo)
ZSH_PLUGINS=(
  "romkatv/powerlevel10k"
  "zsh-users/zsh-completions"
  "zsh-users/zsh-autosuggestions"
  "zsh-users/zsh-syntax-highlighting"
  "agkozak/zsh-z"
)

# ==============================================================================
# 2. Internal Helpers
# ==============================================================================
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERR]${NC}   %s\n" "$*" >&2; }

link_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    warn "Source missing, skipping: $src"
    return 0
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current_target
    current_target="$(readlink "$dst")"
    if [[ "$current_target" == "$src" ]]; then
      ok "$dst -> $src"
      return 0
    fi
    rm -f "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="${dst}.${BACKUP_SUFFIX}"
    warn "Backing up existing file: $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  ok "Linked $dst -> $src"
}

unlink_file() {
  local dst="$1"
  if [[ -L "$dst" ]]; then
    local target
    target="$(readlink "$dst")"
    if [[ "$target" == "$DOTFILES_DIR"* ]]; then
      rm -f "$dst"
      ok "Unlinked $dst"
    fi
  fi
}

check_link() {
  local label="$1"
  local dst="$2"
  local expected="$3"

  if [[ -L "$dst" ]]; then
    local actual
    actual="$(readlink "$dst")"
    if [[ "$actual" == "$expected" ]]; then
      printf "  %-28s ${GREEN}OK${NC} -> %s\n" "$label" "$actual"
    else
      printf "  %-28s ${YELLOW}DRIFTED${NC} -> %s (expected %s)\n" "$label" "$actual" "$expected"
    fi
  elif [[ -e "$dst" ]]; then
    printf "  %-28s ${YELLOW}REGULAR FILE${NC} (%s)\n" "$label" "$dst"
  else
    printf "  %-28s ${RED}MISSING${NC} (%s)\n" "$label" "$dst"
  fi
}

# ==============================================================================
# 3. Commands: link / bootstrap / status / unlink
# ==============================================================================
do_link() {
  info "Linking dotfiles from $DOTFILES_DIR to $TARGET_DIR ..."

  mkdir -p "$TARGET_DIR/.gnupg"
  chmod 700 "$TARGET_DIR/.gnupg"

  for entry in "${DOTFILE_LINKS[@]}"; do
    local src_rel="${entry%%:*}"
    local dst_rel="${entry#*:}"
    link_file "$DOTFILES_DIR/$src_rel" "$TARGET_DIR/$dst_rel"
  done
}

do_bootstrap() {
  info "Bootstrapping external plugins and frameworks..."

  # 1. Zsh plugins
  mkdir -p "$ZSH_PLUGIN_DIR"
  for repo in "${ZSH_PLUGINS[@]}"; do
    local name="${repo#*/}"
    local dest="$ZSH_PLUGIN_DIR/$name"
    if [[ -d "$dest" ]]; then
      ok "Zsh plugin [$name] already installed ($dest)"
    elif [[ -d "$HOME/.zplug/repos/$repo" ]]; then
      info "Migrating Zsh plugin [$name] from ~/.zplug/repos/$repo..."
      cp -a "$HOME/.zplug/repos/$repo" "$dest"
      ok "Migrated Zsh plugin [$name]"
    else
      info "Cloning Zsh plugin [$repo]..."
      git clone --depth 1 "https://github.com/$repo.git" "$dest"
      ok "Installed Zsh plugin [$name]"
    fi
  done

  # 2. Vim (everbird-dotvim)
  local vim_dir="$HOME/.everbird-dotvim"
  if [[ ! -d "$vim_dir" ]]; then
    info "Cloning everbird/dotvim into $vim_dir..."
    git clone --recursive https://github.com/everbird/dotvim.git "$vim_dir"
  else
    ok "everbird-dotvim already present ($vim_dir)"
  fi
  link_file "$vim_dir" "$HOME/.vim"
  link_file "$vim_dir/vimrc" "$HOME/.vimrc"
  [[ -f "$vim_dir/gvimrc" ]] && link_file "$vim_dir/gvimrc" "$HOME/.gvimrc"

  # 3. Tmux Plugin Manager (TPM)
  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [[ -L "$tpm_dir" ]]; then
    local old_tpm
    old_tpm="$(readlink -f "$tpm_dir" || true)"
    rm -f "$tpm_dir"
    if [[ -n "$old_tpm" && -d "$old_tpm/.git" ]]; then
      info "Migrating TPM from $old_tpm to $tpm_dir..."
      mkdir -p "$(dirname "$tpm_dir")"
      cp -a "$old_tpm" "$tpm_dir"
    fi
  fi
  if [[ ! -d "$tpm_dir" ]]; then
    info "Cloning Tmux Plugin Manager (tpm)..."
    mkdir -p "$(dirname "$tpm_dir")"
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_dir"
    ok "Installed TPM ($tpm_dir)"
  else
    ok "Tmux TPM already installed ($tpm_dir)"
  fi

  # 4. Doom Emacs framework
  if [[ -e "$HOME/.emacs.d" ]]; then
    ok "Emacs directory already present ($HOME/.emacs.d)"
  else
    info "Doom Emacs not found at ~/.emacs.d (run: git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.emacs.d && ~/.emacs.d/bin/doom install)"
  fi
}

do_status() {
  info "Dotfiles Symlink Status ($DOTFILES_DIR):"
  for entry in "${DOTFILE_LINKS[@]}"; do
    local src_rel="${entry%%:*}"
    local dst_rel="${entry#*:}"
    check_link "$dst_rel" "$TARGET_DIR/$dst_rel" "$DOTFILES_DIR/$src_rel"
  done

  echo
  info "External Frameworks & Plugins Status:"
  for repo in "${ZSH_PLUGINS[@]}"; do
    local p="${repo#*/}"
    if [[ -d "$ZSH_PLUGIN_DIR/$p" ]]; then
      printf "  %-28s ${GREEN}INSTALLED${NC} (%s)\n" "zsh:$p" "$ZSH_PLUGIN_DIR/$p"
    else
      printf "  %-28s ${RED}MISSING${NC}   (%s)\n" "zsh:$p" "$ZSH_PLUGIN_DIR/$p"
    fi
  done
  check_link "vim (.vim)"   "$HOME/.vim"   "$HOME/.everbird-dotvim"
  check_link "vim (.vimrc)" "$HOME/.vimrc" "$HOME/.everbird-dotvim/vimrc"
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    printf "  %-28s ${GREEN}INSTALLED${NC} (%s)\n" "tmux:tpm" "$HOME/.tmux/plugins/tpm"
  else
    printf "  %-28s ${RED}MISSING${NC}   (%s)\n" "tmux:tpm" "$HOME/.tmux/plugins/tpm"
  fi
}

do_unlink() {
  info "Unlinking dotfiles pointing to $DOTFILES_DIR..."
  for entry in "${DOTFILE_LINKS[@]}"; do
    local dst_rel="${entry#*:}"
    unlink_file "$TARGET_DIR/$dst_rel"
  done
}

cmd="${1:-all}"
case "$cmd" in
  all)
    do_bootstrap
    do_link
    ;;
  link|install)
    do_link
    ;;
  bootstrap)
    do_bootstrap
    ;;
  status)
    do_status
    ;;
  unlink|uninstall)
    do_unlink
    ;;
  *)
    echo "Usage: $0 {all|link|bootstrap|status|unlink}"
    exit 1
    ;;
esac
