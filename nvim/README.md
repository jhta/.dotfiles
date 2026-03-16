# Neovim Config

Using [SpaceVim](https://spacevim.org/) as the base distribution.

## Location

Config lives at `~/.config/nvim/` — SpaceVim manages the full setup.

## Custom files

- `~/.config/nvim/lua/spacevim.lua` — SpaceVim lua compat layer
- `~/.config/nvim/lua/telescope/` — Telescope extensions
- `~/.SpaceVim.d/init.toml` — Your personal SpaceVim config (layers, options)

## Symlink

```sh
# If you want to track your SpaceVim user config:
ln -sf ~/Documents/side-projects/dotfiles-v2/nvim/init.toml ~/.SpaceVim.d/init.toml
```

## Install SpaceVim

```sh
curl -sLf https://spacevim.org/install.sh | bash
```
