
# My .dotfiles

my tools and custom configuration for my terminal (Works on Mac and Ubuntu/Linux).

![terminal](https://github.com/jhta/.dotfiles/blob/master/screenshots/terminal.png)


### terminal tools
`sudo apt-get install vim tmux curl httpie`

Mac:

`brew install vim tmux curl httpie tig`

### git ssh keys
add Email:
` git config --global user.email "jeisonhs93@gmail.com"`
`git clone https://github.com/jhta/gen-ssh-key && cd gen-ssh-key && sh generate-and-send-ssh-key.sh -u jeisonhs93 -d gmail.com`

### oh my zhell
First install `zsh` terminal

Ubuntu/Debian:

`sudo apt-get install zsh`

Mac:

`brew install zsh`

install [oh-my-zhell](https://github.com/robbyrussell/oh-my-zsh):

`sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"`

make zsh the default terminal:

`chsh -s $(which zsh)`

install autosuggestions:
`git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions`

more: https://github.com/zsh-users/zsh-autosuggestions/


### terminal env
I'm using **TMUX** and **VIM** for my terminal.

### VIM
For VIM I used this plugin collection:  
http://vim.spf13.com/

copy the local VIM settings:

`cp .vimrc.local $HOME/`

install plugins:

`vim +BundleInstall! +BundleClean +q`

This has awesome plugins like Bundle, PowerLine, NerdTree and ControlP.

### TMUX

For TMUX I used this configuration for plugins and powerline:  

https://github.com/gpakosz/.tmux  

thiss has a lot of plugins for mouse mode, powerline and more.
I'm using Tmuxp too for load my tmux sessions: https://tmuxp.git-pull.com/en/latest/

### Install kira code

`brew tap caskroom/fonts`
`brew cask install font-fira-code`

__________________
## Custom config

**After install all the tools** run create symbolic links for dotfiles:

`git clone https://github.com/jhta/.dotfiles.git && sh .dotfiles/run.sh`

re-install vim plugins:
`vim +BundleInstall! +BundleClean +q`

### theme:

![prompt](https://github.com/jhta/.dotfiles/blob/master/screenshots/prompt.png)

### plugins

**Autosuggestions:**

![auto](https://github.com/jhta/.dotfiles/blob/master/screenshots/autosuggestions.gif)

**Z:**

![z](https://github.com/jhta/.dotfiles/blob/master/screenshots/z.gif)

### vim

Support for ES6, Graphql, Styled components + Git lens improvments and Monokai as default theme


### Ready for work!

