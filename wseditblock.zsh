# KEY BINDINGS DEFINED IN THIS FILE
# =================================
# ^N=split-line(new-line-after-point)
# ^KB=mark-begin
# ^KK=mark-end
# ^KC=copy
# ^KV=move
# ^KY=delete
# ^KW=save to file (in wskw.zsh)
# ^R=up-screen
# ^C=down-screen
# ^U=undo
# ^6=redo (zle redo)

bindkey -N wseditblock wsedit

## FUNCTIONS
wseditblock-cursupd() {
    if [[ -z $kk && $CURSOR -gt $kb && $CURSOR -le $(( $kb + 2 )) ]]; then
	if [[ -n $1 ]]; then
	    CURSOR=$kb
	else
	    CURSOR=$(( $kb + 3 ))
	fi
    fi
    wsedit-header
}

wseditblock-leave-mode() {
    unset kb
    unset kk
    unset region_highlight
    unset kw
    ws_saved=$wsblock_text
    unset wsblock_text
    zle -K wsedit
}

wseditblock-upd() {
    wsedit-header
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
zle -N wseditblock-up
bindkey -M wseditblock "^E" wseditblock-up
wseditblock-up-line-or-history() {
    if [[ $ws_row -gt 1 ]]; then
        zle up-line
        wseditblock-cursupd 1
    fi
}

zle -N wseditblock-down
bindkey -M wseditblock "^X" wseditblock-down
wseditblock-down-line-or-history() {
    zle down-line
    wseditblock-cursupd
}

zle -N wseditblock-backward-char
bindkey -M wseditblock "^S" wseditblock-backward-char
wseditblock-backward-char() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle backward-char
        wseditblock-cursupd 1
    fi
}

zle -N wseditblock-forward-char
bindkey -M wseditblock "^D" wseditblock-forward-char
wseditblock-forward-char() {
    zle forward-char
    wseditblock-cursupd
}

zle -N wseditblock-beginning-of-line
bindkey -M wseditblock "^Qs" wseditblock-beginning-of-line
bindkey -M wseditblock "^QS" wseditblock-beginning-of-line
wseditblock-beginning-of-line() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle beginning-of-line
        wseditblock-cursupd 1
    fi
}

zle -N wseditblock-end-of-line
bindkey -M wseditblock "^Qd" wseditblock-end-of-line
bindkey -M wseditblock "^QD" wseditblock-end-of-line
wseditblock-end-of-line() {
    zle end-of-line
    wseditblock-cursupd
}

zle -N wseditblock-doc-begin
bindkey -M wseditblock "^Qr" wseditblock-doc-begin
bindkey -M wsedit "^QR" wsedit-doc-begin
wseditblock-doc-begin() {
    CURSOR=$wsedit_begin
    wseditblock-cursupd 1
}

zle -N wseditblock-doc-end
bindkey -M wseditblock "^Qc" wseditblock-doc-end
bindkey -M wseditblock "^QC" wseditblock-doc-end
wseditblock-doc-end() {
    CURSOR=${#BUFFER}
    wseditblock-cursupd
}


zle -N wseditblock-backward-word
bindkey -M wseditblock "^A" wseditblock-backward-word
wseditblock-backward-word() {
    zle backward-word
    if [[ $CURSOR -lt $wsedit_begin ]]; then
        CURSOR=$wsedit_begin
    fi
    wseditblock-cursupd 1
}

zle -N wseditblock-forward-word
bindkey -M wseditblock "^F" wseditblock-forward-word
wseditblock-forward-word() {
    zle forward-word
    wseditblock-cursupd
}


## EDITING: INSERTION
wseditblock-insert-string() {
    local string="$1"
    local curs=$CURSOR
    if [[ -z $kk ]]; then	# state with <B>
	if [[ $curs -le $kb ]]; then
	    kb=$(( $kb + ${#string} ))
	    LBUFFER+="$string"
	elif [[ $curs -gt $(( $kb + 2 )) ]]; then
	    LBUFFER+="$string"
	fi
    else			# state with selection
	LBUFFER+="$string"
	if [[ $curs -lt $kb ]]; then
	    kb=$(( $kb + ${#string} ))
	fi
	if [[ $curs -lt $kk ]]; then
	    kk=$(( $kk + ${#string} ))
	fi
    fi
    wseditblock-upd
}

# insert character
zle -N wseditblock-self-insert
bindkey -M wseditblock -R " "-"~" wseditblock-self-insert
wseditblock-self-insert() {
    wseditblock-insert-string $KEYS
}

zle -N wseditblock-newline
bindkey -M wseditblock "^M" wseditblock-newline
wseditblock-newline() {
    wseditblock-insert-string $'\n'
    wsedit-header
}

# insert line
zle -N wseditblock-splitline
bindkey -M wseditblock "^N" wseditblock-splitline
wseditblock-splitline() {
    local curs=$CURSOR
    wseditblock-insert-string $'\n'
    CURSOR=$curs
    wsedit-header
}

zle -N wseditblock-overwrite
bindkey -M wseditblock "^V" wseditblock-overwrite
wseditblock-overwrite() {
    zle overwrite-mode
    wseditblock-upd
}

## EDITING: DELETING
wseditblock-delupd() { # update $kb, $kk, $kkend, $block text after delete
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
	    wseditblock-leave-mode
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
	    wseditblock-leave-mode
	    return
	fi
    fi
    wseditblock-upd
}

# delete char
zle -N wseditblock-delchar
bindkey -M wseditblock "^G" wseditblock-delchar
wseditblock-delchar() {
    zle delete-char
    wseditblock-delupd
    wsedit-header
}

zle -N wseditblock-backdelchar
bindkey -M wseditblock "^H" wseditblock-backdelchar
bindkey -M wseditblock "^?" wseditblock-backdelchar
wseditblock-backdelchar() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle backward-delete-char
        wseditblock-delupd
        wsedit-header
    fi
}

# delete word
zle -N wseditblock-delword-right
bindkey -M wseditblock "^T" wseditblock-delword-right
wseditblock-delword-right() {
    zle kill-word
    wseditblock-delupd
}

# delete line
zle -N wseditblock-delline
bindkey -M wseditblock "^Y" wseditblock-delline
wseditblock-delline() {
    if [[ $wsedit_begin -lt ${#BUFFER} ]]; then
        zle kill-whole-line
        wseditblock-delupd
        wsedit-header
    fi
}

zle -N wseditblock-delline-right
bindkey -M wseditblock "^Qy" wseditblock-delline-right
bindkey -M wseditblock "^QY" wseditblock-delline-right
wseditblock-delline-right() {
    zle kill-line
    wseditblock-delupd
}

zle -N wseditblock-delline-left
bindkey -M wseditblock "^Q^H" wseditblock-delline-left
wseditblock-delline-left() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle backward-kill-line
        wseditblock-delupd
        wsedit-header
    fi
}

# TODO: connect to killring OR save latest selection on accept/interrupt
wseditblock-kb() {
    zle -K wseditblock
    if [[ -n $kk ]]; then
	unset kk
	unset kb
	unset kw
	unset region_highlight
    fi
    if [[ -z $kb ]]; then
	kb=$CURSOR
	LBUFFER+="<B>"
	kbend=$(( ${#BUFFER} - $kb ))
	CURSOR=$(( $kb + 3 ))
	unset kk
	unset kw
    elif [[ $CURSOR -ge $kb && $CURSOR -le $(( $kb + 3 )) ]]; then
	BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
	CURSOR=$kb
	wseditblock-leave-mode
	return
    else
	if [[ $CURSOR -gt $kb ]]; then
	    CURSOR=$(( $CURSOR - 3 ))
	fi
	BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
	kb=$CURSOR
	kbend=$(( ${#BUFFER} - $kb ))
	LBUFFER+="<B>"
	CURSOR=$(( $kb + 3 ))
    fi
    wseditblock-upd
}

zle -N wsebl-kk
bindkey -M wseditblock "^Kk" wsebl-kk
bindkey -M wseditblock "^KK" wsebl-kk
wsebl-kk() {
    if [[ -z $kk ]]; then
	if [[ $CURSOR -ge $kb && $CURSOR -le $(( $kb + 3 )) ]]; then
	    BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
	    
	    CURSOR=$kb
	    wseditblock-leave-mode
	    return
	fi
	if [[ $CURSOR -gt $kb ]]; then
	    CURSOR=$(( $CURSOR - 3 ))
	fi
	BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
    fi
    if [[ $kb -gt $CURSOR ]]; then
	kk=$kb
	kb=$CURSOR
    else
	kk=$CURSOR
    fi
    wseditblock-upd
}

zle -N wsebl-kc
bindkey -M wseditblock "^Kc" wsebl-kc
bindkey -M wseditblock "^KC" wsebl-kc
wsebl-kc() {
    local curs=$CURSOR
    wseditblock-insert-string $wsblock_text
    CURSOR=$curs
    wsedit-header
}

zle -N wsebl-kv
bindkey -M wseditblock "^Kv" wsebl-kv
bindkey -M wseditblock "^KV" wsebl-kv
wsebl-kv() {
    if [ $CURSOR -ge $kb -a $CURSOR -lt $kk ]; then
	CURSOR=$kb
        wsedit-header
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
        wseditblock-upd
    fi
}

# write selection to file
zle -N wsebl-kw
bindkey -M wseditblock "^Kw" wsebl-kw
bindkey -M wseditblock "^KW" wsebl-kw
wsebl-kw() {
    if [[ -n $kk ]]; then
        wsedit_savebuf=$BUFFER[$(( $wsedit_begin + 1 )),${#BUFFER}]
        wsedit_savecurs=$(( $CURSOR - $wsedit_begin ))
        kb=$(( $kb - $wsedit_begin ))
        kk=$(( $kk - $wsedit_begin ))
        region_highlight=""
        BUFFER=""
        kw_restore="wsebl-kw-restore"
        ws-kwfn
    fi
}

wsebl-kw-restore() {
    wsedit_begin=0
    BUFFER=$wsedit_savebuf
    CURSOR=$wsedit_savecurs
    wseditblock-upd
}

zle -N wsebl-ky
bindkey -M wseditblock "^Ky" wsebl-ky
bindkey -M wseditblock "^KY" wsebl-ky
wsebl-ky() {
    if [[ $CURSOR -ge $kk ]]; then
	local len=$(( $kk - $kb ))
	CURSOR=$(( $CURSOR - $len ))
    elif [[ $CURSOR -ge $kb ]]; then
	CURSOR=$kb
    fi
    BUFFER=$BUFFER[1,$kb]$BUFFER[(( $kk + 1 )),${#BUFFER}]
    wseditblock-leave-mode
    wsedit-header
}

zle -N wseditblock-qb
bindkey -M wseditblock "^Qb" wseditblock-qb
bindkey -M wseditblock "^QB" wseditblock-qb
wseditblock-qb() {
    CURSOR=$kb
    wsedit-header
}

zle -N wseditblock-qk
bindkey -M wseditblock "^Qk" wseditblock-qk
bindkey -M wseditblock "^QK" wseditblock-qk
wseditblock-qk() {
    CURSOR=$kk
    wsedit-header
}

zle -N wseditblock-kr
bindkey -M wseditblock "^Kr" wseditblock-kr
bindkey -M wseditblock "^KR" wseditblock-kr
wseditblock-kr() {
    wsedit_savebuf=$BUFFER[$(( $wsedit_begin + 1 )),${#BUFFER}]
    wsedit_savecurs=$(( $CURSOR - $wsedit_begin ))
    kb=$(( $kb - $wsedit_begin ))
    if [[ -n $kk ]]; then
        kk=$(( $kk - $wsedit_begin ))
    fi
    region_highlight=""
    BUFFER=""
    ws-krfn
    wskr_insert="wseditblock-kr-insert"
}

wseditblock-kr-insert() {
    wsedit_begin=0
    BUFFER=$wsedit_savebuf
    CURSOR=$wsedit_savecurs
    wseditblock-insert-string $wskr_text
    unset wskr_text
}
