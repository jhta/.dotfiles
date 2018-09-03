GREEN="%{$fg_bold[green]%}"
WHITE="%{$fg_bold[white]%}"
CYAN="%{$fg_bold[cyan]%}"
RED="%{$fg_bold[red]%}"
YELLOW="%{$fg_bold[yellow]%}"
RESET="%{$reset_color%}"

PROMPT='$GREEN⬢  $WHITE%c $(git_prompt_info) $RESET'

ZSH_THEME_GIT_PROMPT_PREFIX="$YELLOW⇒  $RED"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" $YELLOW⦾"
ZSH_THEME_GIT_PROMPT_CLEAN=" $GREEN⦾"
