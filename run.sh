#!/bin/bash

BASEDIR="$(cd "$(dirname "$0")" && pwd)/"



ln -sf "$BASEDIR/zshrc" "$HOME/.chupelo"
ln -sf "$BASEDIR/vimrc.local" "$HOME/.vimrc.local"

echo "Symbolik links created for .zshrc and .vimrc.local"
