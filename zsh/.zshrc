# =============================================================================
# .zshrc — Jeison Higuita
# v2 — 2026
# =============================================================================

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Plugins
plugins=(git z jsontools copypath copyfile colored-man-pages)

source $ZSH/oh-my-zsh.sh

# =============================================================================
# PATH
# =============================================================================

export PATH=/opt/homebrew/bin:$PATH
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="$HOME/.flashlight/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Maestro
export PATH=$PATH:$HOME/.maestro/bin

# =============================================================================
# JAVA / ANDROID
# =============================================================================

export JAVA_HOME=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home

# =============================================================================
# RUNTIME MANAGERS
# =============================================================================

# rbenv
eval "$(rbenv init - --no-rehash zsh)"

# RVM (must be last PATH change)
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# pipx
. "$HOME/.local/bin/env"

# =============================================================================
# SECRETS — load from ~/.secrets (never commit that file)
# =============================================================================
# Create ~/.secrets with the following vars:
#   export GITHUB_TOKEN=""
#   export OPENAI_API_KEY=""
#   export FIGMA_ACCESS_TOKEN=""
#   export CLICKUP_AUTH_KEY=""
#   export CLICKUP_API_KEY=""
#   export SLITE_API_KEY=""

[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# =============================================================================
# ZSH PLUGINS (brew-installed)
# =============================================================================

# Autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting — must be sourced last
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
