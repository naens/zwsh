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

# debug file: contains the definition debug output file name
# If such file does not exist, do not use debuging.
# This file is gitignored in order to prevent useless file modifications and
# commits.
# See function zwdbg in wsfun for information on switch on and off
# debugging.
if [[ -f "$srcdir/wsdebug-tty.zsh" ]]; then
    source "$srcdir/wsdebug-tty.zsh"
fi

# completion settings
zstyle ':completion:*:default' menu no-select
#unsetopt auto_menu
#setopt BASH_AUTO_LIST

autoload -Uz compinit
compinit

# zsh ws theme

tabs -8 > /dev/null        # use standard tabs for this theme

# set terminal options
stty -ixon

#stty intr    undef 2> /dev/null # ^C
stty kill    undef 2> /dev/null # ^U
stty eof     undef 2> /dev/null # ^D
stty start   undef 2> /dev/null # ^Q
stty stop    undef 2> /dev/null # ^S
#stty susp    undef 2> /dev/null # ^Z
stty rprnt   undef 2> /dev/null # ^R
stty werase  undef 2> /dev/null # ^W
stty lnext   undef 2> /dev/null # ^V
stty discard undef 2> /dev/null # ^O

stty eof '^\\'

stty erase '^H'

#setopt EXTENDED_GLOB

# global variables and functions
. $srcdir/wsfun.zsh

# text navigation functions
. $srcdir/wstxtfun.zsh

# wstext
. $srcdir/wstext.zsh

# bind ws keys
. $srcdir/wskeys.zsh

# ws block functions
. $srcdir/wsblock.zsh

# line mode
. $srcdir/wsline.zsh

# dialog mode
. $srcdir/wsdialog.zsh

# file for ^KX, ^KS and ^KW binding functions for file writing
. $srcdir/wsdfsave.zsh

# file for ^KR binding functions and file import
. $srcdir/wsdfopen.zsh

# file for ^KQ binding
. $srcdir/wsdquit.zsh

# display message
. $srcdir/wsdinfo.zsh

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


# FUTURE: directory autocompletion

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

ws_pts=$(tty)

# Load user file
userfile=~/.zwrc
if [[ -f $userfile ]]; then
    . $userfile
fi

bindkey -A wskeys main
