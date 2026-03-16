# dotfiles v2

> Personal macOS developer environment

## What's inside

| Directory | Contents |
|-----------|----------|
| `zsh/` | `.zshrc`, `.secrets.template` |
| `git/` | `.gitconfig` (with delta), `.gitignore_global` |
| `nvim/` | SpaceVim `init.toml` |
| `cursor/` | `settings.json`, `keybindings.json`, `extensions.txt` |
| `scripts/` | `install.sh` |
| `Brewfile` | All Homebrew packages |

## Stack

- **Shell**: zsh + oh-my-zsh + zsh-autosuggestions + zsh-syntax-highlighting
- **Prompt**: robbyrussell
- **Terminal multiplexer**: cmux
- **Editor**: Neovim (SpaceVim) + Cursor
- **Git**: delta (side-by-side diffs), lazygit, tig
- **Runtime managers**: nvm, rbenv, bun
- **Mobile dev**: maestro, fastlane, scrcpy, cocoapods

## Install

```sh
git clone https://github.com/jhta/.dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh
```

## Secrets

Secrets are **never committed**. After install, fill in `~/.secrets`:

```sh
# ~/.secrets
export GITHUB_TOKEN=""
export OPENAI_API_KEY=""
export FIGMA_ACCESS_TOKEN=""
export CLICKUP_AUTH_KEY=""
export CLICKUP_API_KEY=""
export SLITE_API_KEY=""
```

## Cursor extensions

To install all Cursor extensions:

```sh
grep -v '^#' cursor/extensions.txt | grep -v '^$' | xargs -L 1 cursor --install-extension
```

To export your current extensions (keep this updated):

```sh
cursor --list-extensions > cursor/extensions.txt
```
