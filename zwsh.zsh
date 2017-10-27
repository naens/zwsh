# ZWSHDIR: directory of the program part, read-only
if [[ -n "$ZWSHDIR" ]]; then
    srcdir="$ZWSHDIR"
else
    echo "no ZWSHDIR variable available"
    exit
fi

if [[ ! -d "$ZWSHDIR" ]]; then
    echo "no ZWSHDIR=$ZWSHDIR directory"
    exit
fi

# completion settings
zstyle ':completion:*:default' menu no-select
#unsetopt auto_menu
#setopt BASH_AUTO_LIST

autoload -Uz compinit
compinit

# zsh ws theme

tabs -8        # use standard tabs for this theme

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
. $srcdir/wsfun.zsh

# text navigation functions
. $srcdir/wstxtfun.zsh

# wstext
. $srcdir/wstext.zsh

# bind ws keys
. $srcdir/wskeys.zsh

# line mode
. $srcdir/wsline.zsh

# dialog mode
. $srcdir/wsdialog.zsh
	    
# ws block functions
. $srcdir/wsblock.zsh

# file for ^KW binding functions and file writing
. $srcdir/wsdfsave.zsh

# file for ^KR binding functions and file import
. $srcdir/wsdfopen.zsh

# ws find key bindings
. $srcdir/wsfind.zsh

# ws editor mode
. $srcdir/wsedit.zsh

# Examples of Special folders for .zshrc
# typeset -A zw_special_folders
# zw_special_folders[FONTS]=~/Documents/fonts
# zw_special_folders[TMP]=/tmp
# zw_special_folders[PROJ]=~/projects
# zw_special_folders[DOC]=~/Documents
# zw_special_folders[V]=~/Videos
# zw_special_folders[OPT]=/opt


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
if (($EUID != 0)); then
    export PROMPT='$(collapse_pwd)>'
else
    export PROMPT='$(collapse_pwd)# '
fi


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
