# Prevent Ubuntu/Debian /etc/zsh/zshrc from running a redundant compinit
# before ~/.zshrc configures fpath and completion caching.
skip_global_compinit=1

# Rust / Cargo environment
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
