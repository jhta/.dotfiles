#!/usr/bin/env bash
# =============================================================================
# install.sh — dotfiles v2 setup
# Usage: ./scripts/install.sh
# =============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Installing dotfiles from: $DOTFILES_DIR"

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

link() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ] || [ -L "$dst" ]; then
    echo "  [skip] $dst already exists (backup: ${dst}.bak)"
    mv "$dst" "${dst}.bak"
  fi
  ln -sf "$src" "$dst"
  echo "  [link] $src → $dst"
}

# -----------------------------------------------------------------------------
# 1. Homebrew packages
# -----------------------------------------------------------------------------
echo ""
echo ">>> Installing Homebrew packages..."
if command -v brew &>/dev/null; then
  brew bundle --file="$DOTFILES_DIR/Brewfile"
else
  echo "  [warn] brew not found, skipping. Install from https://brew.sh"
fi

# -----------------------------------------------------------------------------
# 2. Shell — zsh
# -----------------------------------------------------------------------------
echo ""
echo ">>> Linking zsh config..."
link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"

# Set up secrets file if missing
if [ ! -f "$HOME/.secrets" ]; then
  cp "$DOTFILES_DIR/zsh/.secrets.template" "$HOME/.secrets"
  echo "  [note] Created ~/.secrets from template — fill in your API keys"
fi

# -----------------------------------------------------------------------------
# 3. Git
# -----------------------------------------------------------------------------
echo ""
echo ">>> Linking git config..."
link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

# -----------------------------------------------------------------------------
# 4. Neovim / SpaceVim
# -----------------------------------------------------------------------------
echo ""
echo ">>> Setting up Neovim..."
if [ ! -d "$HOME/.SpaceVim" ]; then
  echo "  Installing SpaceVim..."
  curl -sLf https://spacevim.org/install.sh | bash
fi
mkdir -p "$HOME/.SpaceVim.d"
link "$DOTFILES_DIR/nvim/init.toml" "$HOME/.SpaceVim.d/init.toml"

# -----------------------------------------------------------------------------
# 5. Cursor / VS Code
# -----------------------------------------------------------------------------
echo ""
echo ">>> Setting up Cursor..."

CURSOR_USER="$HOME/Library/Application Support/Cursor/User"

if [ -d "$CURSOR_USER" ]; then
  link "$DOTFILES_DIR/cursor/settings.json" "$CURSOR_USER/settings.json"
  link "$DOTFILES_DIR/cursor/keybindings.json" "$CURSOR_USER/keybindings.json"
  echo "  Installing Cursor extensions..."
  if command -v cursor &>/dev/null; then
    grep -v '^#' "$DOTFILES_DIR/cursor/extensions.txt" | grep -v '^$' | xargs -L 1 cursor --install-extension
  else
    echo "  [warn] cursor CLI not found. Install extensions manually from cursor/extensions.txt"
  fi
else
  echo "  [skip] Cursor not installed"
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo "✓ Done! Restart your terminal or run: source ~/.zshrc"
echo ""
echo "Next steps:"
echo "  1. Fill in ~/.secrets with your API keys"
echo "  2. Set up nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash"
echo "  3. Set up rbenv ruby: rbenv install <version>"
