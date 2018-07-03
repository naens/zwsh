# SINGLE LINE EDITING MODE
# ========================
# $wsline_maxlen=maximal length of the line
# keybindings to switch to other line, as well as ^M and Enter
# are by default disabled.
# if $wsline_maxlen is 0, then mute mode

bindkey -N wsline wskeys
bindkey -M wsline -r "^Ke"
bindkey -M wsline -r "^KE"
bindkey -M wsline -r "^Kd"
bindkey -M wsline -r "^KD"
bindkey -M wsline -r "^Ks"
bindkey -M wsline -r "^KS"
bindkey -M wsline -r "^Kx"
bindkey -M wsline -r "^KX"
bindkey -M wsline -r "^Km"
bindkey -M wsline -r "^KM"
bindkey -M wsline -r "^E"
bindkey -M wsline -r "^X"

# initialize mode and insert field at $begin in BUFFER
wsline-init() {
    local name=$1
    local begin=$2
    local len=$3
    local marksvar=$4
    local visvar=$5
    eval "wsline_${name}_begin=$begin"
    eval "wsline_${name}_len=$len"
    eval "wsline_${name}_text=''"
    eval "wsline-${name}-update() { wsline-update $name }"
    eval "wsline_${name}_textpos=0"
    eval "wsline_${name}_caller_marksvar=$marksvar"
    eval "wsline_${name}_caller_visvar=$visvar"
    declare -gA wsline_${name}_marksvar

    local mode=wsline-${name}-mode
    bindkey -N $mode wsline
    if typeset -f wsline-${name}-accept > /dev/null; then
        zle -N wsline-${name}-accept
        bindkey -M $mode "^M" wsline-${name}-accept
    fi
    if typeset -f wsline-${name}-cancel > /dev/null; then
        zle -N wsline-${name}-cancel
        bindkey -M $mode "^U" wsline-${name}-cancel
        bindkey -M $mode "^Kq" wsline-${name}-cancel
        bindkey -M $mode "^KQ" wsline-${name}-cancel
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
    wstext_marksvar=wsline_${name}_marksvar
    wstext_blockvisvar=wsline_${name}_blockvisvar
    wstext_blockcolmodevar=wsline_${name}_blockcolmodevar
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
    unset wsline_${name}_marksvar
    unset wsline_${name}_blockvisvar
    unset wsline_${name}_blockcolmodevar
    unset wstext_textvar
    unset wstext_updfnvar
    unset wstext_posvar
}

# Function: wsline-get-display-pos
#     Converts text to display representation:
#      - insert <B> and <K> where needed
#      - insert ^J instead of newline
#
# Parameters:
#     $1 - name
#     $2 - text
#
# Returns:
#     prints the display version of the text
#
wsline-get-display-text() {
    local name="$1"
    local text="$2"
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    local vis=${(P)wstext_blockvisvar}
    ws-debug WSLINE_GET_DISPLAY_TEXT: "name=$name text=$text"
    ws-debug WSLINE_GET_DISPLAY_TEXT: b_pos=$b_pos k_pos=$k_pos vis=$vis
    if [[ -z "$vis" ]]; then
        b_pos=""
        k_pos=""
    fi
    ws-debug WSLINE_GET_DISPLAY_TEXT: "text=$text b_pos=$b_pos k_pos=$k_pos"
}

# Function: wsline-display-pos
#     Converts positions in text to what they will be when displayed.
#     <B> and <K>, while not taking space in text, are of width 3 when dislpayed.
#     Control characters (^O, ^P) are counted as a single character in text,
#     but are two characters when displayed.
#     The newlines character is counted as '^J', because it is displayed
#     this way in wsline mode.
#
# Parameters:
#     $1 - text
#     $2 - sorted array of positions to convert
#
# Returns:
#     prints values of corresponding positions
#
wsline-convert-display-pos() {
    local text=$1
    local positions=$2
#    ws-debug WSLINE_CONVERT_DISLPAY_POS: "text=$text positions=$positions"
    # TODO
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

    ws-debug WSLINE_UPDATE: name=$name begin=$begin text=\"$text\"
#    ws-debug WSLINE_UPDATE: tlen=$tlen flen=$flen textpos=$textpos oldscroll=$oldscroll scrollpos=$scrollpos
    local cursorpos=$((begin+textpos-scrollpos))
    local display_text=$(wsline-get-display-text "$name" "$text")
    read fstart pos <<< $(wsline-convert-display-pos \
    				"$name" "$text" "($begin $cursorpos)")
    BUFFER[begin+1,begin+flen]="$text[1+scrollpos,flen+scrollpos]"
    ws-insert-xtimes $((begin+tlen-scrollpos)) $((scrollpos+flen-tlen)) "-"
    #TODO: * display <B>, <K> + cursor skip <B>/<K>
    #TODO: * exchange with buffer: ^U and ^KB/^KK and back
    #TODO: * length: with control characters and <B>/<K> elements
#    ws-debug cursorpos=$cursorpos
    CURSOR=$((begin+textpos-scrollpos))
}
