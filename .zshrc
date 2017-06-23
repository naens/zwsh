# TEMP: directory
#dir=$(dirname $0)
if [[ -n $ZDOTDIR ]]; then
    dir=$ZDOTDIR
else
    dir="~"
fi

# completion settings
zstyle ':completion:*:default' menu no-select
#unsetopt auto_menu
#setopt BASH_AUTO_LIST

autoload -Uz compinit
compinit

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

#setopt EXTENDED_GLOB

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
. $dir/tests/wsline-test.zsh
. $dir/tests/wsdialog-test.zsh

# special folders
typeset -A zw_special_folders

zw_special_folders[FONTS]=~/Documents/fonts
zw_special_folders[ELEC]=~/Documents/Prog/elec
zw_special_folders[QMS]=~/Documents/Prog/qms

zw_special_folders[TMP]=/tmp
zw_special_folders[PROJ]=~/projects
zw_special_folders[DOC]=~/Documents
zw_special_folders[V]=~/Videos
zw_special_folders[LOG]=/var/log
zw_special_folders[OPT]=/opt
zw_special_folders[ISO]=~/Downloads/iso


# TODO directory autocompletion

for k in ${(k)zw_special_folders}; do
    folder=$zw_special_folders[$k]
    alias -g "$k:"="\"$folder\""
#    eval "$k: () { cd \"$folder\" }"
done

setopt auto_cd

# prompt functions
function collapse_pwd
{
    local pwd=$(pwd)
    local wdk=""
    local wdsub=""
    for k in ${(k)zw_special_folders}; do
        folder=$zw_special_folders[$k]
        if [[ "$pwd" = "$folder"* ]]; then
            wdk=$k
            wdsub=$(echo $pwd | sed -e "s,^$folder,,")
        fi
    done
    if [[ -z "$wdk" && "$pwd" == "$HOME"* ]]; then
        wdk=ZSH
        wdsub=$(echo $pwd | sed -e "s,^$HOME,," )
    fi
    if [[ -n "$wdk" ]]; then
        echo "$wdk"$(echo "$wdsub" | sed -e "s,/,:,")
    else
        echo "ZSH$pwd"
    fi
}

setopt PROMPT_SUBST
export PROMPT='$(collapse_pwd)>'

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
