### KEYBINDINGS ###
# ^KB=mark-begin
# ^KK=mark-end
# ^KC=copy
# ^KV=move
# ^KY=delete
# ^KW=save to file
# ^KH=hide block
# ^KN=column mode

### VARIABLES ###
# $wsblock_kb: position of <B>
# $wsblock_kk: position of <K>
# $wsblock_col: defined if column mode on
# $wsblock_vis: defined if block is in visible mode

## FUNCTIONS
wsblock-cursupd() {
    if [[ -z $kk && $CURSOR -gt $kb && $CURSOR -le $(( $kb + 2 )) ]]; then
	if [[ -n $1 ]]; then
	    CURSOR=$kb
	else
	    CURSOR=$(( $kb + 3 ))
	fi
    fi
}

wsblock-leave() {
    unset kb
    unset kk
    unset region_highlight
    unset kw
    ws_saved=$wsblock_text
    unset wsblock_text
}

wsblock-upd() {
    kbend=$(( ${#BUFFER} - $kb ))
    if [[ -n $kk ]]; then
	kkend=$(( ${#BUFFER} - $kk ))
	wsblock_text=$BUFFER[$(( $kb + 1 )),$kk]
	region_highlight=("$kb $kk standout")
    else
	region_highlight=("$kb $(( $kb + 3)) standout")
    fi
}


## CURSOR
zle -N wsblock-up-line-or-history
bindkey -M wsblock "^E" wsblock-up-line-or-history
wsblock-up-line-or-history() {
    zle up-line-or-history
    wsblock-cursupd 1
}

zle -N wsblock-down-line-or-history
bindkey -M wsblock "^X" wsblock-down-line-or-history
wsblock-down-line-or-history() {
    zle down-line-or-history
    wsblock-cursupd
}

zle -N wsblock-backward-char
bindkey -M wsblock "^S" wsblock-backward-char
wsblock-backward-char() {
    zle backward-char
    wsblock-cursupd 1
}

zle -N wsblock-forward-char
bindkey -M wsblock "^D" wsblock-forward-char
wsblock-forward-char() {
    zle forward-char
    wsblock-cursupd
}

zle -N wsblock-beginning-of-line
bindkey -M wsblock "^Qs" wsblock-beginning-of-line
bindkey -M wsblock "^QS" wsblock-beginning-of-line
wsblock-beginning-of-line() {
    zle beginning-of-line
    wsblock-cursupd 1
}

zle -N wsblock-end-of-line
bindkey -M wsblock "^Qd" wsblock-end-of-line
bindkey -M wsblock "^QD" wsblock-end-of-line
wsblock-end-of-line() {
    zle end-of-line
    wsblock-cursupd
}

zle -N wsblock-backward-word
bindkey -M wsblock "^A" wsblock-backward-word
wsblock-backward-word() {
    zle backward-word
    wsblock-cursupd 1
}

zle -N wsblock-forward-word
bindkey -M wsblock "^F" wsblock-forward-word
wsblock-forward-word() {
    zle forward-word
    wsblock-cursupd
}

# insert character
zle -N wsblock-self-insert
bindkey -M wsblock -R " "-"~" wsblock-self-insert
wsblock-self-insert() {
    wsblock-insert-string $KEYS
}

zle -N wsblock-accept
bindkey -M wsblock "^M" wsblock-accept
wsblock-accept() {
    if [[ -z $kk ]]; then
        BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
    fi
#    zle -M "buffer=#$BUFFER#"
    wsblock-leave-mode
    zle accept-line
}

# insert line
zle -N wsblock-split-line
bindkey -M wsblock "^N" wsblock-split-line
wsblock-split-line() {
    wsblock-insert-string \\$'\n'
}

## EDITING: DELETING
wsblock-delupd() { # update $kb, $kk, $kkend, $block text after delete
    cursend=$(( ${#BUFFER} - $CURSOR ))
    local len=$(( $kb + $kbend - ${#BUFFER} )) # old buffer size - new buffer size
    if [[ -z $kk ]]; then
	local kbb=$(( $kb + 3 ))
	local kbbend=$(( $kbend - 3 ))
#	zle -M "### kb=$kb kbend=$kbend kbb=$kbb kbbend=$kbbend curs=$CURSOR cursend=$cursend"
	if [[ $kbbend -gt $cursend && $CURSOR -ge $kbb ]]; then
	    kbend=$(( $kbend - $len ))
	elif [[ $kb -gt $CURSOR && $cursend -ge $kbend ]]; then
	    local okb=$kb
	    kb=$(( $kb - $len ))
	else
	    if [[ $kb -ge $CURSOR && $kbbend -lt $cursend ]]; then
		local end=$(( $CURSOR + $cursend - $kbbend + 1 ))
		BUFFER=$BUFFER[1,$CURSOR]$BUFFER[$end,${#BUFFER}]
#		zle -M "LEAVE[1]: kb=$kb kbend=$kbend kbb=$kbb kbbend=$kbbend curs=$CURSOR cursend=$cursend"
	    elif [[ $kb -lt $CURSOR && $kbb -gt $curs ]]; then
		BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $CURSOR + 1 )),${#BUFFER}]
		CURSOR=$kb
#		zle -M "LEAVE[2]: kb=$kb kbend=$kbend kbb=$kbb kbbend=$kbbend curs=$CURSOR cursend=$cursend"
	    fi
	    wsblock-leave-mode
	    return
	fi
    else
#	zle -M "kb=$kb kbend=$kbend kk=$kk kkend=$kkend curs=$CURSOR len=$len"
	if [[ $cursend -lt $kbend && $CURSOR -lt $kb ]]; then
	    kb=$CURSOR
	elif [[ $CURSOR -lt $kb ]]; then
	    kb=$(( $kb - $len ))
	fi
	if [[ $cursend -lt $kkend &&  $CURSOR -lt $kk ]]; then
	    kk=$CURSOR
	elif [[ $CURSOR -lt $kk ]]; then
	    kk=$(( $kk - $len ))
	fi
	if [[ $(( $kk  - $kb )) -lt 1 ]]; then
	    wsblock-leave-mode
	    return
	fi
    fi
    wsblock-upd
}

# delete char
zle -N wsblock-delchar
bindkey -M wsblock "^G" wsblock-delchar
wsblock-delchar() {
    zle delete-char-or-list
    wsblock-delupd
}

zle -N wsblock-backdelchar
bindkey -M wsblock "^H" wsblock-backdelchar
bindkey -M wsblock "^?" wsblock-backdelchar
wsblock-backdelchar() {
    zle backward-delete-char
    wsblock-delupd
}

# delete word
zle -N wsblock-delword-right
bindkey -M wsblock "^T" wsblock-delword-right
wsblock-delword-right() {
    zle kill-word
    wsblock-delupd
}

# delete line
zle -N wsblock-delline
bindkey -M wsblock "^Y" wsblock-delline
wsblock-delline() {
    zle kill-whole-line
    wsblock-delupd
}

zle -N wsblock-delline-right
bindkey -M wsblock "^Qy" wsblock-delline-right
bindkey -M wsblock "^QY" wsblock-delline-right
wsblock-delline-right() {
    zle kill-line
    wsblock-delupd
}

zle -N wsblock-delline-left
bindkey -M wsblock "^Q^H" wsblock-delline-left
wsblock-delline-left() {
    zle backward-kill-line
    wsblock-delupd
}

zle -N ws-kb
bindkey -M wskeys "^Kb" ws-kb
bindkey -M wskeys "^KB" ws-kb
ws-kb() {
    local pos=${(P)wstext_posvar}
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    if [[ -n "$wsblock_vis" && -n "$b_pos" && "$b_pos" -eq $pos ]]; then
        unset "${wstext_marksvar}[B]"
        if [[ -z "$k_pos" ]]; then
            unset wsblock_vis
        fi
    else
    	eval "${wstext_marksvar}[B]=$pos"
        wsblock_vis=true
    fi
    # if $wsblock_col is undefined, leave undefined (by default column mode off)
    wstext-upd
}

zle -N ws-kk
bindkey -M wskeys "^Kk" ws-kk
bindkey -M wskeys "^KK" ws-kk
ws-kk() {
    local pos=${(P)wstext_posvar}
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    if [[ -n "$wsblock_vis" && -n "$k_pos" && "$k_pos" -eq $pos ]]; then
        unset "${wstext_marksvar}[K]"
        if [[ -z "$b_pos" ]]; then
            unset wsblock_vis
        fi
    else
    	eval "${wstext_marksvar}[K]=$pos"
        wsblock_vis=true
    fi
#    # if $wsblock_col is undefined, leave undefined (by default column mode off)
    wstext-upd
}

zle -N ws-kc
bindkey -M wsblock "^Kc" ws-kc
bindkey -M wsblock "^KC" ws-kc
ws-kc() {
    local curs=$CURSOR
    wsblock-insert-string $wsblock_text
    CURSOR=$curs
}

zle -N ws-kv
bindkey -M wsblock "^Kv" ws-kv
bindkey -M wsblock "^KV" ws-kv
ws-kv() {
    if [ $CURSOR -ge $kb -a $CURSOR -lt $kk ]; then
	CURSOR=$kb
    else
        local curs=$CURSOR
        BUFFER=$BUFFER[1,$kb]$BUFFER[(( $kk + 1 )),${#BUFFER}]
	if [[ $curs -ge $kk ]]; then
	    curs=$(( $curs - ${#wsblock_text} ))
            CURSOR=$curs
        fi
        LBUFFER+=$wsblock_text
        CURSOR=$curs
	kb=$CURSOR
	kk=$(( $kb + ${#wsblock_text} ))
        wsblock-upd
    fi
}

# write selection to file
zle -N ws-kw
bindkey -M wsblock "^Kw" ws-kw
bindkey -M wsblock "^KW" ws-kw
ws-kw() {
    if [[ -n $kk ]]; then
#        ws-kwfn
        wsdialog_kwdial-run
    fi
}

zle -N ws-ky
bindkey -M wsblock "^Ky" ws-ky
bindkey -M wsblock "^KY" ws-ky
ws-ky() {
    if [[ $CURSOR -ge $kk ]]; then
	local len=$(( $kk - $kb ))
	CURSOR=$(( $CURSOR - $len ))
    elif [[ $CURSOR -ge $kb ]]; then
	CURSOR=$kb
    fi
    BUFFER=$BUFFER[1,$kb]$BUFFER[(( $kk + 1 )),${#BUFFER}]
    wsblock-leave-mode
}

zle -N wsblock-qb
bindkey -M wsblock "^Qb" wsblock-qb
bindkey -M wsblock "^QB" wsblock-qb
wsblock-qb() {
    CURSOR=$kb
}

zle -N wsblock-qk
bindkey -M wsblock "^Qk" wsblock-qk
bindkey -M wsblock "^QK" wsblock-qk
wsblock-qk() {
    CURSOR=$kk
}

zle -N wsblock-kr
bindkey -M wsblock "^Kr" wsblock-kr
bindkey -M wsblock "^KR" wsblock-kr
wsblock-kr() {
    ws-krfn
    wskr_insert="wsblock-kr-insert"
}

wsblock-kr-insert() {
    wsblock-insert-string $wskr_text
    unset wskr_text
}
