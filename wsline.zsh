# SINGLE LINE EDITING MODE
# ========================
# $wsline_maxlen=maximal length of the line
# keybindings to switch to other line, as well as ^M and Enter
# are by default disabled.
# if $wsline_maxlen is 0, then mute mode

bindkey -N wsline

wsline-init() {
    wsline_update=$1
    wsline_begin=$(( $CURSOR ))
    wsline_end=$(( ${#BUFFER} - $CURSOR ))
    if [[ $wsline_maxlen -ge 1 ]]; then
	wsline_delpoint=$(( $wsline_begin + $wsline_maxlen - 1 ))
    else
	wsline_delpoint=$wsline_begin
    fi
}

wsline-update() {
    if [[ -n $wsline_update ]]; then
        $wsline_update
    fi
}

# insertions
zle -N wsline-self-insert
bindkey -M wsline -R "!"-"~" wsline-self-insert
bindkey -M wsline " " wsline-self-insert
wsline-self-insert() {
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
	BUFFER[$CURSOR]=""
	CURSOR=$(( $CURSOR - 1 ))
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
    local len1=${#BUFFER}
    zle kill-word
    local len2=${#BUFFER}
    local restlen=$(( ${#BUFFER} - $CURSOR ))
    if [[ $restlen -lt $wsline_end ]]; then
	RBUFFER=$endsaved
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
