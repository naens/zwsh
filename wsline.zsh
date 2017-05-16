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

    local mode=wsline-${name}-mode
    bindkey -N $mode wsline
    if typeset -f wsline-${name}-accept > /dev/null; then
        bindkey -M $mode "^M" wsline-${name}-accept
    fi
    if typeset -f wsline-${name}-cancel > /dev/null; then
        bindkey -M $mode "^U" wsline-${name}-cancel
    fi
    while [[ $# -gt 4 ]]; do
        local key="$4"
        local fun="$5"
        bindkey -M $mode "$key" "$fun"
        shift
        shift
    done

    ws-insert-xtimes $begin $len "_"
}

# cursor on wsline, text on first position, switch to mode
wsline-activate() {
    local name=$1

   # save previous state
    eval "wsline_${name}_prevtextvar=$wstext_textvar"
    eval "wsline_${name}_prevupdfnvar=$wstext_updfnvar"
    eval "wsline_${name}_prevmode=$KEYMAP"

   # enter new state
    wstext_textvar=wsline_${name}_text
    wstext_updfnvar=wsline-${name}-update
    wstext_posvar=wsline_${name}_textpos
    local beginvar=wsline_${name}_begin

    ws-debug WSLINE: entering wsline-${name}-mode, begin=${(P)beginvar}

    zle -K wsline-${name}-mode
    eval "wsline_${name}_scrollpos=0"
    wsline-update $name
}

# remove wsline, enter previous mode
wsline-exit() {
    local name=$1
    local from=$wsline_begin
    local to=$((wsline_begin+wsline_len))
    BUFFER[from,to]=""

    local prevtextvarvar=wsline_${name}_pervtextvar
    wstext_textvar=${(P)prevtextvarvar}
    local prevupdfnvarvar=wsline_${name}_prevupdfnvar
    wstext_updfnvar=${(P)prevupdfnvarvar}
    local modevar=wsline_${name}_prevmode
    zle -K ${(P)modevar}
}

wsline-accept() {
    local name=$1
    $name-acceptfn
}

wsline-cancel() {
    local name=$1
    $name-cancelfn
}

wsline-prepare() {
    local name=$1

    zle -N wsline-$name-accept
    bindkey -M ${1}_line "^M" wsline-$name-accept
    eval "wsline-$name-accept() { wsline-accept $name }"

    zle -N wsline-$name-cancel
    bindkey -M ${1}_line "^U" wsline-$name-cancel
    eval "wsline-$name-cancel() { wsline-cancel $name }"
}

# wsline variables:
#  - begin: position where the editable area begins
#  - len: length of the editable area
#  - text: variable containing the contents of the text

# called when closing wsline
wsline-finalize() {
    local name=$1
    unset wsline_${name}_begin
    unset wsline_${name}_len
    unset wsline_${name}_text
}

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
    local scrollpos=$(ws-max $(ws-min ${(P)scrollposvar} $((tlen-flen))) 0)
    local posvar=wsline_${name}_textpos
    local pos=${(P)textpos}


    ws-debug WSLINE_UPDATE: name=$name flen=$flen tlen=$tlen begin=$begin
    # TODO: skip beginning, if scroll not at first position
    # TODO: place cursor: !!!textpos + fieldpos
    if [[ $flen -le $tlen ]]; then
        BUFFER[begin+1,begin+flen]="$text[1,flen]"
    else
        BUFFER[begin+1,begin+flen]="$text"
        ws-insert-xtimes $((begin+tlen)) $((flen-tlen)) "."
    fi
    ws-debug WSLINE_UPDATE: begin=$begin textpos=$textpos scrollpos=$scrollpos
    CURSOR=$((begin+textpos-scrollpos))
}

# Cursor Keys: Characters
zle -N wsline-back
bindkey -M wsline "^S" wsline-back
wsline-back() {
}

zle -N wsline-forward
bindkey -M wsline "^D" wsline-forward
wsline-forward() {
}

# Cursor Keys: Words
zle -N wsline-backward-word
bindkey -M wsline "^A" wsline-backward-word
wsline-backward-word() {
}

zle -N wsline-forward-word
bindkey -M wsline "^F" wsline-forward-word
wsline-forward-word() {
}

# Cursor Keys: Lines
zle -N wsline-begin
bindkey -M wsline "^Qs" wsline-begin
bindkey -M wsline "^QS" wsline-begin
wsline-begin() {
}

zle -N wsline-end
bindkey -M wsline "^Qd" wsline-end
bindkey -M wsline "^QD" wsline-end
wsline-end() {
}

# Cursor Keys: Sentences

# Cursor Keys: Paragraphs

bindkey -M wsline "^R" wsline-begin
bindkey -M wsline "^C" wsline-end

# Other Keys
bindkey -M wsline "^M" undefined-key
bindkey -M wsline "^J" undefined-key
bindkey -M wsline "^I" undefined-key
