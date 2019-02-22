#!/bin/bash

BASEDIR="$(cd "$(dirname "$0")" && pwd)/"


cp "$HOME/.zshrc" "$HOME/.zshrc.original"
cp "$HOME/.vimrc.local" "$HOME/.vimrc.local.original"

ln -sf "$BASEDIR/zshrc" "$HOME/.zshrc"
ln -sf "$BASEDIR/vimrc.local" "$HOME/.vimrc.local"

echo "Symbolic links created for .zshrc and .vimrc.local"

#install fira code
brew tap caskroom/fonts
brew cask install font-fira-code

echo "Fira code font installed"

ln -sf "$BASEDIR/node.zsh-theme" "$HOME/.oh-my-zsh/themes/node.zsh-theme"
echo "__________________________________"
echo "Symbolic link added for node.zsh-theme"

