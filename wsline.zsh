# SINGLE LINE EDITING MODE
# ========================
# $wsline_maxlen=maximal length of the line
# keybindings to switch to other line, as well as ^M and Enter
# are by default disabled.
# if $wsline_maxlen is 0, then mute mode

bindkey -N wsline wskeys

# initialize mode and insert field at $begin in BUFFER
wsline-init() {
    local name=$1
    local begin=$2
    local len=$3
    eval "wsline_${name}_begin=$begin"
    eval "wsline_${name}_len=$len"
    eval "wsline_${name}_text=''"
    eval "wsline-${name}-update() { wsline-update $name }"
    eval "wsline_${name}_textpos=0"

    local mode=wsline-${name}-mode
    bindkey -N $mode wsline
    if typeset -f wsline-${name}-accept > /dev/null; then
        zle -N wsline-${name}-accept
        bindkey -M $mode "^M" wsline-${name}-accept
    fi
    if typeset -f wsline-${name}-cancel > /dev/null; then
        zle -N wsline-${name}-cancel
        bindkey -M $mode "^U" wsline-${name}-cancel
    fi
#    ws-debug WSLINE_INIT: name=$name
#    ws-debug WSLINE_INIT"{1}": CURSOR=$CURSOR begin=$begin len=$len
    ws-insert-xtimes $begin $len " "
#    ws-debug WSLINE_INIT"{2}": CURSOR=$CURSOR
}

wsline-add-key() {
    local mode=$1
    local key="$2"
    local fun="$3"
    zle -N $fun
    bindkey -M $mode "$key" "$fun"
}

# cursor on wsline, text on first position, switch to mode
wsline-activate() {
    local name=$1

   # enter new state
    wstext_textvar=wsline_${name}_text
    wstext_updfnvar=wsline-${name}-update
    wstext_posvar=wsline_${name}_textpos
    local beginvar=wsline_${name}_begin

#    ws-debug WSLINE_ACTIVATE: entering mode \"wsline-${name}-mode\", begin=${(P)beginvar}

    zle -K wsline-${name}-mode
#    eval "wsline_${name}_scrollpos=0"
    wsline-update $name
}

wsline-exit() {
    local name=$1

    unset wsline_${name}_begin
    unset wsline_${name}_len
    unset wsline_${name}_text
    unset wsline_${name}_textpos
    unset wsline_${name}_update
    unset wstext_textvar
    unset wstext_updfnvar
    unset wstext_posvar
}

# wsline variables:
#  - begin: position where the editable area begins
#  - len: length of the editable area
#  - text: variable containing the contents of the text

wsline-update() {
    local name=$1
    local textvar=wsline_${name}_text
    local text="${(P)textvar}"
    local tlen=${#text}
    local flenvar=wsline_${name}_len
    local flen=${(P)flenvar}
    local beginvar=wsline_${name}_begin
    local begin=${(P)beginvar}
    
    local scrollposvar=wsline_${name}_scrollpos
    local posvar=wsline_${name}_textpos
    local textpos=${(P)posvar}

    local oldscroll=${(P)scrollposvar}
    local scrollpos=$(ws-get-scrollpos $tlen $flen $textpos $oldscroll)
    eval "$scrollposvar=$scrollpos"

#    ws-debug WSLINE_UPDATE: name=$name begin=$begin text=\"$text\"
#    ws-debug WSLINE_UPDATE: tlen=$tlen flen=$flen textpos=$textpos oldscroll=$oldscroll scrollpos=$scrollpos
    BUFFER[begin+1,begin+flen]="$text[1+scrollpos,flen+scrollpos]"
    ws-insert-xtimes $((begin+tlen-scrollpos)) $((scrollpos+flen-tlen)) " "
    local cursorpos=$((begin+textpos-scrollpos))
#    ws-debug cursorpos=$cursorpos
    CURSOR=$((begin+textpos-scrollpos))
}
