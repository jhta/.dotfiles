
# Configuration


### terminal tools
`sudo apt-get install vim tmux curl httpie`

Mac:

`brew install vim tmux curl httpie`

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

For VIM I used this plugin collection:  
http://vim.spf13.com/

copy the local VIM settings:

`cp .vimrc.local $HOME/`

install plugins:

`vim +BundleInstall! +BundleClean +q`

This has awesome plugins like Bundle, PowerLine, NerdTree and ControlP.  

For TMUX I used this configuration:  

https://github.com/gpakosz/.tmux  

thiss has a lot of plugins for mouse mode, powerline and more.
I'm using Tmuxp too for load my tmux sessions: https://tmuxp.git-pull.com/en/latest/

## Custom config

`git clone https://github.com/jhta/.dotfiles.git && sh .dotfiles/run.sh`
