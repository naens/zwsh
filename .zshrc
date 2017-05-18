# TEMP: directory
#dir=$(dirname $0)
if [[ -n $ZDOTDIR ]]; then
    dir=$ZDOTDIR
else
    dir="~"
fi

# zsh ws theme

# set terminal options
stty -ixon

#stty intr    undef # ^C
stty kill    undef # ^U
#stty eof     undef # ^D
stty start   undef # ^Q
stty stop    undef # ^S
stty susp    undef # ^Z
stty rprnt   undef # ^R
stty werase  undef # ^W
stty lnext   undef # ^V
stty discard undef # ^O

stty eof '^\\'
stty intr '^]'

stty erase '^H'

setopt EXTENDED_GLOB

zmodload zsh/pcre

# global variables and functions
. $dir/wsfun.zsh

# text navigation functions
. $dir/wstxtfun.zsh

# wstext
. $dir/wstext.zsh

# bind ws keys
. $dir/wskeys.zsh

# line mode
. $dir/wsline.zsh

# dialog mode
. $dir/wsdialog.zsh
	    
# ws block functions
. $dir/wsblock.zsh

# file for ^KW binding functions and file writing
. $dir/wsdfsave.zsh

# file for ^KR binding functions and file import
. $dir/wsdfopen.zsh

# ws find key bindings
. $dir/wsfind.zsh

# ws editor mode
. $dir/wsedit.zsh

# load tests
. $dir/tests/*

# prompt functions
function collapse_pwd
{
    if [[ $(pwd) == $HOME* ]]; then
	subdir=$(pwd | sed -e "s,^$HOME,,")
	echo $subdir | sed -e "s,/,:,"
    else
	echo $(pwd)
    fi
}

setopt PROMPT_SUBST
export PROMPT=ZSH'$(collapse_pwd)>'

# options completion
#setopt menu_complete
#setopt auto_menu
#autoload -Uz compinit
#compinit
#zstyle ':completion:*' menu yes select

HISTFILE=~/.zsh_history

# Remember about a years worth of history (AWESOME)
SAVEHIST=10000
HISTSIZE=10000

bindkey -A wskeys main
