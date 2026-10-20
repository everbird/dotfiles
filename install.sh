#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}"
BACKUP_SUFFIX="bak.$(date +%Y%m%d%H%M%S)"
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERR]${NC}   %s\n" "$*" >&2; }

# Safely create/update a symlink: link_file <source_abs_path> <target_abs_path>
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

# Unlink if pointing into DOTFILES_DIR
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

do_link() {
  info "Linking dotfiles from $DOTFILES_DIR to $TARGET_DIR ..."

  # Adopt ~/.p10k.zsh into repo if not yet present in zsh/.p10k.zsh
  if [[ ! -f "$DOTFILES_DIR/zsh/.p10k.zsh" && -f "$TARGET_DIR/.p10k.zsh" && ! -L "$TARGET_DIR/.p10k.zsh" ]]; then
    info "Adopting existing ~/.p10k.zsh into repository..."
    cp "$TARGET_DIR/.p10k.zsh" "$DOTFILES_DIR/zsh/.p10k.zsh"
  fi

  # 1. Zsh
  link_file "$DOTFILES_DIR/zsh/.zshenv" "$TARGET_DIR/.zshenv"
  link_file "$DOTFILES_DIR/zsh/.zshrc" "$TARGET_DIR/.zshrc"
  [[ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]] && link_file "$DOTFILES_DIR/zsh/.p10k.zsh" "$TARGET_DIR/.p10k.zsh"

  # 2. Git
  link_file "$DOTFILES_DIR/git/.gitconfig" "$TARGET_DIR/.gitconfig"
  link_file "$DOTFILES_DIR/git/.config/git/ignore" "$TARGET_DIR/.config/git/ignore"

  # 3. Tmux
  link_file "$DOTFILES_DIR/tmux/.tmux.conf" "$TARGET_DIR/.tmux.conf"

  # 4. EditorConfig
  link_file "$DOTFILES_DIR/editorconfig/.editorconfig" "$TARGET_DIR/.editorconfig"

  # 5. Doom Emacs config
  for f in init.el config.el packages.el custom.el; do
    link_file "$DOTFILES_DIR/doom/.doom.d/$f" "$TARGET_DIR/.doom.d/$f"
  done

  # 6. GPG Agent (OS-aware)
  mkdir -p "$TARGET_DIR/.gnupg"
  chmod 700 "$TARGET_DIR/.gnupg"
  case "$(uname -s)" in
    Darwin*)
      link_file "$DOTFILES_DIR/gpg/gpg-agent.conf.macos" "$TARGET_DIR/.gnupg/gpg-agent.conf"
      ;;
    Linux*)
      link_file "$DOTFILES_DIR/gpg/gpg-agent.conf.linux" "$TARGET_DIR/.gnupg/gpg-agent.conf"
      ;;
  esac
}

do_bootstrap() {
  info "Bootstrapping external plugins and frameworks..."

  # 1. Zsh plugins
  mkdir -p "$ZSH_PLUGIN_DIR"
  local zsh_repos=(
    "romkatv/powerlevel10k"
    "zsh-users/zsh-completions"
    "zsh-users/zsh-autosuggestions"
    "zsh-users/zsh-syntax-highlighting"
    "agkozak/zsh-z"
  )
  for repo in "${zsh_repos[@]}"; do
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

do_status() {
  info "Dotfiles Symlink Status ($DOTFILES_DIR):"
  check_link ".zshenv"             "$TARGET_DIR/.zshenv"             "$DOTFILES_DIR/zsh/.zshenv"
  check_link ".zshrc"              "$TARGET_DIR/.zshrc"              "$DOTFILES_DIR/zsh/.zshrc"
  check_link ".p10k.zsh"           "$TARGET_DIR/.p10k.zsh"           "$DOTFILES_DIR/zsh/.p10k.zsh"
  check_link ".gitconfig"          "$TARGET_DIR/.gitconfig"          "$DOTFILES_DIR/git/.gitconfig"
  check_link ".config/git/ignore"  "$TARGET_DIR/.config/git/ignore"  "$DOTFILES_DIR/git/.config/git/ignore"
  check_link ".tmux.conf"          "$TARGET_DIR/.tmux.conf"          "$DOTFILES_DIR/tmux/.tmux.conf"
  check_link ".editorconfig"       "$TARGET_DIR/.editorconfig"       "$DOTFILES_DIR/editorconfig/.editorconfig"
  check_link ".doom.d/config.el"   "$TARGET_DIR/.doom.d/config.el"   "$DOTFILES_DIR/doom/.doom.d/config.el"
  check_link ".doom.d/init.el"     "$TARGET_DIR/.doom.d/init.el"     "$DOTFILES_DIR/doom/.doom.d/init.el"
  check_link ".doom.d/packages.el" "$TARGET_DIR/.doom.d/packages.el" "$DOTFILES_DIR/doom/.doom.d/packages.el"

  case "$(uname -s)" in
    Darwin*) check_link ".gnupg/gpg-agent.conf" "$TARGET_DIR/.gnupg/gpg-agent.conf" "$DOTFILES_DIR/gpg/gpg-agent.conf.macos" ;;
    Linux*)  check_link ".gnupg/gpg-agent.conf" "$TARGET_DIR/.gnupg/gpg-agent.conf" "$DOTFILES_DIR/gpg/gpg-agent.conf.linux" ;;
  esac

  echo
  info "External Frameworks & Plugins Status:"
  for p in powerlevel10k zsh-completions zsh-autosuggestions zsh-syntax-highlighting zsh-z; do
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
  unlink_file "$TARGET_DIR/.zshenv"
  unlink_file "$TARGET_DIR/.zshrc"
  unlink_file "$TARGET_DIR/.p10k.zsh"
  unlink_file "$TARGET_DIR/.gitconfig"
  unlink_file "$TARGET_DIR/.config/git/ignore"
  unlink_file "$TARGET_DIR/.tmux.conf"
  unlink_file "$TARGET_DIR/.editorconfig"
  for f in init.el config.el packages.el custom.el; do
    unlink_file "$TARGET_DIR/.doom.d/$f"
  done
  unlink_file "$TARGET_DIR/.gnupg/gpg-agent.conf"
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
