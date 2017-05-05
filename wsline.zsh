# SINGLE LINE EDITING MODE
# ========================
# $wsline_maxlen=maximal length of the line
# keybindings to switch to other line, as well as ^M and Enter
# are by default disabled.
# if $wsline_maxlen is 0, then mute mode

bindkey -N wsline

wsline-init() {
    local name=$1
    local update=$2
    local begin=$CURSOR
    local end=$(( ${#BUFFER} - $CURSOR ))
    local v=wsline_${name}_maxlen
    local maxlen=${(P)v}
    eval wsline_${name}_update=$update
    eval wsline_${name}_begin=$begin
    eval wsline_${name}_end=$end
    eval wsline_${name}_maxlen=$maxlen
    if [[ $maxlen -ge 1 ]]; then
        local delpoint=$(( $begin + $maxlen - 1 ))
    else
	local delpoint=$begin
    fi
    eval wsline_${name}_delpoint=$delpoint
    wsline-getvars $name
    wsline-update
#    echo wsline: update=$update begin=$begin end=$end v=$v > $debugfile
#    echo wsline: name=$name delpoint=$delpoint maxlen=$maxlen > $debugfile
}

wsline-accept() {
    local name=$1
    wsline-setvars $name
    $name-acceptfn
}

wsline-cancel() {
    local name=$1
    wsline-setvars $name
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

# called when closing wsline
wsline-finalize() {
    local name=$1
    unset wsline_${name}_update
    unset wsline_${name}_begin
    unset wsline_${name}_end
    unset wsline_${name}_len
    unset wsline_${name}_text
    unset wsline_${name}_delpoint
    unset wsline_update
    unset wsline_begin
    unset wsline_end
    unset wsline_len
    unset wsline_text
    unset wsline_delpoint
}

wsline-getvars() {
    local name=$1
    local v=wsline_${name}_update
    wsline_update=${(P)v}
    v=wsline_${name}_begin
    wsline_begin=${(P)v}
    v=wsline_${name}_end
    wsline_end=${(P)v}
    v=wsline_${name}_len
    wsline_len=${(P)v}
    v=wsline_${name}_text
    wsline_text=${(P)v}
    v=wsline_${name}_delpoint
    wsline_delpoint=${(P)v}
    v=wsline_${name}_maxlen
    wsline_maxlen=${(P)v}
#    echo WSLINE_GETVARS: begin=$wsline_begin end=$wsline_end len=$wsline_len text=$wsline_text maxlen=$wsline_maxlen > $debugfile
}

wsline-setvars() {
    local name=$1
    eval wsline_${name}_update=$wsline_update
    eval wsline_${name}_begin=$wsline_begin
    eval wsline_${name}_end=$wsline_end
    eval wsline_${name}_len=$wsline_len
    eval wsline_${name}_text=\'$wsline_text\'
    eval wsline_${name}_delpoint=$wsline_delpoint
    eval wsline_${name}_maxlen=$wsline_maxlen
#    echo WSLINE_SETVARS: begin=$wsline_begin end=$wsline_end len=$wsline_len text=$wsline_text maxlen=$wsline_maxlen > $debugfile
}


wsline-update() {
    wsline_len=$(( ${#BUFFER} - $wsline_begin - $wsline_end ))
    wsline_text=$BUFFER[wsline_begin+1,wsline_begin+wsline_len]
    if [[ -n $wsline_update ]]; then
        $wsline_update
    fi
}

zle -N wsline-self-insert
bindkey -M wsline -R "!"-"~" wsline-self-insert
bindkey -M wsline " " wsline-self-insert
# insertions
wsline-self-insert() {
#    echo wsline-self-insert: update=$wsline_update begin=$wsline_begin end=$wsline_end > $debugfile
#    echo wsline-self-insert: delpoint=$wsline_delpoint maxlen=$wsline_maxlen> $debugfile
    if [[ wsline_maxlen -lt 1 ]]; then
	return
    fi
    if [[ $ZLE_STATE == *insert* ]]; then
	LBUFFER+=$KEYS
    elif [[ $ZLE_STATE == *overwrite* ]]; then
	if [[ $CURSOR -lt $(( ${#BUFFER} - $wsline_end )) ]]; then
	    BUFFER[$(( $CURSOR + 1 ))]=$KEYS
	    if [[ $CURSOR -lt $(( ${#BUFFER} - $wsline_end - 1)) ]]; then
		CURSOR=$(( $CURSOR + 1 ))
	    fi
	fi
    fi
    local length=$(( ${#BUFFER} - $wsline_begin - $wsline_end ))
    local lastchar=$(( $wsline_begin + $length ))
    if [[ $lastchar -gt $wsline_delpoint ]]; then
	local end=$(( ${#BUFFER} - $wsline_end  + 1 ))
	local p1=$BUFFER[1,$(( $wsline_delpoint + 1 ))]
	local p2=$BUFFER[$end,${#BUFFER}]
	BUFFER=$p1$p2
    fi
    if [[ $CURSOR -gt $wsline_delpoint ]]; then
	CURSOR=$wsline_delpoint
    fi
    wsline-update
}

# Cursor Keys
zle -N wsline-back
bindkey -M wsline "^S" wsline-back
wsline-back() {
    if [[ $CURSOR -gt $wsline_begin ]]; then
	CURSOR=$(( $CURSOR - 1 ))
    fi
}

zle -N wsline-forward
bindkey -M wsline "^D" wsline-forward
wsline-forward() {
    local end=$(( ${#BUFFER} - $wsline_end ))
    if [[ $CURSOR -lt $wsline_delpoint && $CURSOR -lt $end ]]; then
	CURSOR=$(( $CURSOR + 1 ))
    fi
}

zle -N wsline-begin
bindkey -M wsline "^Qs" wsline-begin
bindkey -M wsline "^QS" wsline-begin
wsline-begin() {
    CURSOR=$wsline_begin
}

zle -N wsline-end
bindkey -M wsline "^Qd" wsline-end
bindkey -M wsline "^QD" wsline-end
wsline-end() {
    local length=$(( ${#BUFFER} - $wsline_begin - $wsline_end ))
    if [[ $length -eq $wsline_maxlen ]]; then
	CURSOR=$wsline_delpoint
    else
	local end=$(( ${#BUFFER} - $wsline_end ))
	CURSOR=$end
    fi
}

zle -N wsline-backward-word
bindkey -M wsline "^A" wsline-backward-word
wsline-backward-word() {
    zle backward-word
    if [[ $CURSOR -lt $wsline_begin ]]; then
	CURSOR=$wsline_begin
    fi
}

zle -N wsline-forward-word
bindkey -M wsline "^F" wsline-forward-word
wsline-forward-word() {
    zle forward-word
    local length=$(( ${#BUFFER} - $wsline_begin - $wsline_end ))
    if [[ $wsline_maxlen -eq $length && $CURSOR -gt $(( $wsline_delpoint - 1 )) ]]; then
	CURSOR=$wsline_delpoint
    else
        local maxcursval=$(( $wsline_begin + $length ))
        if [[ $wsline_maxlen -gt $length && $CURSOR -gt $maxcursval ]]; then
	    CURSOR=$maxcursval
        fi
    fi
}

bindkey -M wsline "^R" wsline-begin
bindkey -M wsline "^C" wsline-end

bindkey -M wsline "^Q^[" undefined-key
bindkey -M wsline "^K^[" undefined-key

# Delete Keys
zle -N wsline-delchar
bindkey -M wsline "^G" wsline-delchar
wsline-delchar() {
    local end=$(( ${#BUFFER} - $wsline_end ))
    if [[ $CURSOR -lt $end ]]; then
	BUFFER[$(( $CURSOR + 1 ))]=""
    fi
    wsline-update
}

zle -N wsline-backdelchar
bindkey -M wsline "^H" wsline-backdelchar
bindkey -M wsline "^?" wsline-backdelchar
wsline-backdelchar() {
    if [[ $CURSOR -gt $wsline_begin ]]; then
        local curs=$CURSOR
	BUFFER[$CURSOR]=""
	CURSOR=$(( $curs - 1 ))
    fi
    wsline-update
}

zle -N wsline-delline
bindkey -M wsline "^Y" wsline-delline
wsline-delline() {
    local end=$(( ${#BUFFER} - $wsline_end + 1 ))
    BUFFER=$BUFFER[1,$wsline_begin]$BUFFER[$end,${#BUFFER}]
    CURSOR=$wsline_begin
    wsline-update
}

zle -N wsline-delword-right
bindkey -M wsline "^T" wsline-delword-right
wsline-delword-right() {
    local end=$(( ${#BUFFER} - $wsline_end + 1 ))
    local endsaved=$BUFFER[$end,${#BUFFER}]
    zle kill-word
    local restlen=$(( ${#BUFFER} - $CURSOR ))
    if [[ $restlen -lt $wsline_end ]]; then
	RBUFFER=$endsaved
    fi
    wsline-update
}

zle -N wsline-delword-left
bindkey -M wsline "^[h" wsline-delword-left
bindkey -M wsline "^[H" wsline-delword-left
wsline-delword-left() {
    local begin=$BUFFER[1,$wsline_begin]
    zle backward-kill-word
    if [[ $CURSOR -lt $wsline_begin ]]; then
        LBUFFER=$begin
    fi
}

zle -N wsline-delword
bindkey -M wsline "^[y" wsline-delword
bindkey -M wsline "^[Y" wsline-delword
wsline-delword() {
    local begin=$BUFFER[1,$wsline_begin]
    local end=$(( ${#BUFFER} - $wsline_end + 1 ))
    local endsaved=$BUFFER[$end,${#BUFFER}]
    delword
    local restlen=$(( ${#BUFFER} - $CURSOR ))
    if [[ $restlen -lt $wsline_end ]]; then
	RBUFFER=$endsaved
    fi
    if [[ $CURSOR -lt $wsline_begin ]]; then
        LBUFFER=$begin
    fi
    wsline-update
}

zle -N wsline-delline-right
bindkey -M wsline "^Qy" wsline-delline-right
bindkey -M wsline "^QY" wsline-delline-right
wsline-delline-right() {
    local end=$(( ${#BUFFER} - $wsline_end + 1 ))
    BUFFER=$BUFFER[1,$CURSOR]$BUFFER[$end,${#BUFFER}]
    wsline-update
}

zle -N wsline-delline-left
bindkey -M wsline "^Q^H" wsline-delline-left
wsline-delline-left() {
    BUFFER=$BUFFER[1,$wsline_begin]$BUFFER[$(( $CURSOR + 1 )),${#BUFFER}]
    CURSOR=$wsline_begin
    wsline-update
}

# Undo Keys
bindkey -M wsline "^U" undo
bindkey -M wsline "^6" redo

# Other Keys
bindkey -M wsline "^M" undefined-key
bindkey -M wsline "^J" undefined-key
bindkey -M wsline "^V" overwrite-mode
bindkey -M wsline "^I" undefined-key
