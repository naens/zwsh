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

wsblock-undef() {
    ws-debug WSBLOCK_UNDEF
    if [[ -n "${wstext_marksvar}" ]]; then
        unset "${wstext_marksvar}[B]"
        unset "${wstext_marksvar}[K]"
    fi
    if [[ -n "${wstext_blockvisvar}" ]]; then
        eval "unset $wstext_blockvisvar"
    fi
    if [[ -n "${wstext_blockcolmodevar}" ]]; then
        eval "unset ${wstext_blockcolmodevar}"
    fi
}


#wsblock-upd() {
#    kbend=$(( ${#BUFFER} - $kb ))
#    if [[ -n $kk ]]; then
#        kkend=$(( ${#BUFFER} - $kk ))
#        wsblock_text=$BUFFER[$(( $kb + 1 )),$kk]
#        region_highlight=("$kb $kk standout")
#    else
#        region_highlight=("$kb $(( $kb + 3)) standout")
#    fi
#}


## CURSOR
#zle -N wsblock-up-line-or-history
#bindkey -M wsblock "^E" wsblock-up-line-or-history
wsblock-up-line-or-history() {
    zle up-line-or-history
    wsblock-cursupd 1
}

#zle -N wsblock-down-line-or-history
#bindkey -M wsblock "^X" wsblock-down-line-or-history
wsblock-down-line-or-history() {
    zle down-line-or-history
    wsblock-cursupd
}

#zle -N wsblock-backward-char
#bindkey -M wsblock "^S" wsblock-backward-char
wsblock-backward-char() {
    zle backward-char
    wsblock-cursupd 1
}

#zle -N wsblock-forward-char
#bindkey -M wsblock "^D" wsblock-forward-char
wsblock-forward-char() {
    zle forward-char
    wsblock-cursupd
}

#zle -N wsblock-beginning-of-line
#bindkey -M wsblock "^Qs" wsblock-beginning-of-line
#bindkey -M wsblock "^QS" wsblock-beginning-of-line
wsblock-beginning-of-line() {
    zle beginning-of-line
    wsblock-cursupd 1
}

#zle -N wsblock-end-of-line
#bindkey -M wsblock "^Qd" wsblock-end-of-line
#bindkey -M wsblock "^QD" wsblock-end-of-line
wsblock-end-of-line() {
    zle end-of-line
    wsblock-cursupd
}

#zle -N wsblock-backward-word
#bindkey -M wsblock "^A" wsblock-backward-word
wsblock-backward-word() {
    zle backward-word
    wsblock-cursupd 1
}

#zle -N wsblock-forward-word
#bindkey -M wsblock "^F" wsblock-forward-word
wsblock-forward-word() {
    zle forward-word
    wsblock-cursupd
}

# insert character
#zle -N wsblock-self-insert
#bindkey -M wsblock -R " "-"~" wsblock-self-insert
wsblock-self-insert() {
    wsblock-insert-string $KEYS
}

#zle -N wsblock-accept
#bindkey -M wsblock "^M" wsblock-accept
wsblock-accept() {
    if [[ -z $kk ]]; then
        BUFFER=$BUFFER[1,$kb]$BUFFER[$(( $kb + 4 )),${#BUFFER}]
    fi
#    zle -M "buffer=#$BUFFER#"
    wsblock-leave-mode
    zle accept-line
}

# insert line
#zle -N wsblock-split-line
#bindkey -M wsblock "^N" wsblock-split-line
wsblock-split-line() {
    wsblock-insert-string \\$'\n'
}

wsblock-delupd() {
    local from=$1
    local to=$2
    if [[ "$wstext_blockcolmodevar" = "true" ]]; then
    else
        local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
        local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
        local dlen=$((to-from))
        ws-debug WSBLOCK_DELUPD: from=$from to=$to b_pos=$b_pos k_pos=$k_pos
        if [[ -n "$b_pos" && -n "$k_pos" && $b_pos -lt $k_pos ]]; then
            if [[ $b_pos -ge $from && $k_pos -le $to ]]; then
                ws-debug WSBLOCK_DELUPD: undef BK
                wsblock-undef
            fi
        else
            if [[ -n "$b_pos" ]]; then
                if [[ $b_pos -ge $from && $b_pos -le $to ]]; then
                    unset "${wstext_marksvar}[B]"
                    ws-debug WSBLOCK_DELUPD: undef B
                    b_pos=""
                fi
            fi
            if [[ -n "$k_pos" ]]; then
                if [[ $k_pos -ge $from && $b_pos -le $to ]]; then
                    unset "${wstext_marksvar}[K]"
                    ws-debug WSBLOCK_DELUPD: undef K
                    k_pos=""
                fi
            fi
            if [[ "$b_pos" = "" && "$k_pos" = "" ]]; then
                wsblock-undef
            fi
        fi
    fi
}

# delete char
#zle -N wsblock-delchar
#bindkey -M wsblock "^G" wsblock-delchar
wsblock-delchar() {
    zle delete-char-or-list
    wsblock-delupd
}

#zle -N wsblock-backdelchar
#bindkey -M wsblock "^H" wsblock-backdelchar
#bindkey -M wsblock "^?" wsblock-backdelchar
wsblock-backdelchar() {
    zle backward-delete-char
    wsblock-delupd
}

# delete word
#zle -N wsblock-delword-right
#bindkey -M wsblock "^T" wsblock-delword-right
wsblock-delword-right() {
    zle kill-word
    wsblock-delupd
}

# delete line
#zle -N wsblock-delline
#bindkey -M wsblock "^Y" wsblock-delline
wsblock-delline() {
    zle kill-whole-line
    wsblock-delupd
}

#zle -N wsblock-delline-right
#bindkey -M wsblock "^Qy" wsblock-delline-right
#bindkey -M wsblock "^QY" wsblock-delline-right
wsblock-delline-right() {
    zle kill-line
    wsblock-delupd
}

#zle -N wsblock-delline-left
#bindkey -M wsblock "^Q^H" wsblock-delline-left
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
    local vis=${(P)wstext_blockvisvar}
    if [[ -n "$vis" && -n "$b_pos" && "$b_pos" -eq $pos ]]; then
        unset "${wstext_marksvar}[B]"
        if [[ -z "$k_pos" ]]; then
            eval "unset $wstext_blockvisvar"
        fi
    else
        eval "${wstext_marksvar}[B]=$pos"
        eval "$wstext_blockvisvar=true"
    fi
    # if $wsblock_col is undefined, leave undefined (by default column mode off)
    ws-debug WS_KB: b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    wstext-upd
}

zle -N ws-kk
bindkey -M wskeys "^Kk" ws-kk
bindkey -M wskeys "^KK" ws-kk
ws-kk() {
    local pos=${(P)wstext_posvar}
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    local vis=${(P)wstext_blockvisvar}
    if [[ -n "$vis" && -n "$k_pos" && "$k_pos" -eq $pos ]]; then
        unset "${wstext_marksvar}[K]"
        if [[ -z "$b_pos" ]]; then
            eval "unset $wstext_blockvisvar"
        fi
    else
        eval "${wstext_marksvar}[K]=$pos"
        eval "$wstext_blockvisvar=true"
    fi
    ws-debug WS_KK: k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
#    # if $wsblock_col is undefined, leave undefined (by default column mode off)
    wstext-upd
}

zle -N wsblock-kh
bindkey -M wskeys "^Kh" wsblock-kh
bindkey -M wskeys "^KH" wsblock-kh
wsblock-kh() {
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    local vis=${(P)wstext_blockvisvar}
    if [[ -n "$vis" ]]; then
        eval "unset $wstext_blockvisvar"
    elif [[ -n "$b_pos" || -n "$k_pos" ]]; then
        eval "$wstext_blockvisvar=true"
    fi
    wstext-upd
}

zle -N ws-kn
bindkey -M wskeys "^Kn" wsblock-kn
bindkey -M wskeys "^KN" wsblock-kn
wsblock-kn() {
    local vis=${(P)wstext_blockvisvar}
    if [[ -n "$vis"  && -n "$wstext_blockcolmodevar" ]]; then
        local colmode=${(P)wstext_blockcolmodevar}
        if [[ -n "$colmode" ]]; then
            eval "unset $wstext_blockcolmodevar"
        else
            eval "$wstext_blockcolmodevar=true"
        fi
        wstext-upd
    fi
}

zle -N wsblock-kc
bindkey -M wskeys "^Kc" wsblock-kc
bindkey -M wskeys "^KC" wsblock-kc
wsblock-kc() {
    if [[ -z "${(P)wstext_blockvisvar}" ]]; then
        # no block selected: paste last deleted text
        if [[ -n "$ws_delbuf" ]]; then
            wstext-insert "$ws_delbuf"
        fi
        return
    fi
    if [[ "$wstext_blockcolmodevar" = "true" ]]; then
    else
        local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
        local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
        if [[ -n "$b_pos" && -n "$k_pos" && "$b_pos" -lt "$k_pos" ]]; then
            local text=${(P)wstext_textvar}
            local block=$text[b_pos+1,k_pos]
            local pos=${(P)wstext_posvar}
            wstext-insert "$block"
            eval "${wstext_posvar}=$pos"
            wstext-upd
        fi
    fi
}

zle -N wsblock-kv
bindkey -M wskeys "^Kv" wsblock-kv
bindkey -M wskeys "^KV" wsblock-kv
wsblock-kv() {
    if [[ -z "${(P)wstext_blockvisvar}" ]]; then
        # no block selected: paste last deleted text
        if [[ -n "$ws_delbuf" ]]; then
            wstext-insert "$ws_delbuf"
        fi
        return
    fi
    local text=${(P)wstext_textvar}
    local pos=${(P)wstext_posvar}
    if [[ "$wstext_blockcolmodevar" = "true" ]]; then
    else
        local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
        local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
        if [[ -n "$b_pos" && -n "$k_pos" && "$b_pos" -lt "$k_pos" ]]; then
            ws-debug WSBLOCK_KV: pos=$pos b_pos=$b_pos k_pos=$k_pos
            local block=$text[b_pos+1,k_pos]
            local len=${#block}
            if [[ $pos -lt $b_pos ]]; then
                # cursor before block
                wstext-delete $((b_pos+1)) $k_pos
                wstext-insert "$block"
                b_pos=$pos
                k_pos=$((b_pos+len))
            elif [[ $pos -ge $k_pos ]]; then
                # cursor after block
                wstext-insert "$block"
                wstext-delete $((b_pos+1)) $k_pos
                b_pos=$((pos-len))
                k_pos=$pos
            fi
            eval "${wstext_marksvar}[B]=$b_pos"
            eval "${wstext_marksvar}[K]=$k_pos"
            eval "${wstext_posvar}=$b_pos"
            eval "$wstext_blockvisvar=true"
        fi
    fi
    wstext-upd
}

# write selection to file
zle -N wsblock-kw
bindkey -M wskeys "^Kw" wsblock-kw
bindkey -M wskeys "^KW" wsblock-kw
wsblock-kw() {
    local pos=${(P)wstext_posvar}
    local text=${(P)wstext_textvar}
    if [[ "$wstext_blockcolmodevar" = "true" ]]; then
    else
        local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
        local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
        if [[ -n "$b_pos" && -n "$k_pos" && "$b_pos" -lt "$k_pos" ]]; then
            wsdfsave_text=$text[b_pos+1,k_pos]
            wsdfsave-run
        else
            wsdinfo_l1="#You have not yet defined a block. Use ^KB and ^KK."
            wsdinfo_l3="*Press Esc to continue.*"
            wsdinfo-run
        fi
    fi
}

zle -N wsblock-ky
bindkey -M wskeys "^Ky" wsblock-ky
bindkey -M wskeys "^KY" wsblock-ky
wsblock-ky() {
    if [[ -z "${(P)wstext_blockvisvar}" ]]; then
        return
    fi
    local pos=${(P)wstext_posvar}
    local text=${(P)wstext_textvar}
    if [[ "$wstext_blockcolmodevar" = "true" ]]; then
    else
        local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
        local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
        if [[ -n "$b_pos" && -n "$k_pos" && "$b_pos" -lt "$k_pos" ]]; then
            local block=$text[b_pos+1,k_pos]
            local len=${#block}
            wstext-delete $((b_pos+1)) $k_pos
            if [[ $pos -ge $b_pos && $pos -lt $k_pos ]]; then
                pos=$b_pos
            elif [[ $pos -ge $k_pos ]]; then
                pos=$((pos-len))
            fi
            eval "${wstext_posvar}=$pos"
            wsblock-undef
        fi
    fi
    wstext-upd
}

zle -N wsblock-qb
bindkey -M wskeys "^Qb" wsblock-qb
bindkey -M wskeys "^QB" wsblock-qb
wsblock-qb() {
    local b_pos=$(eval "echo \${${wstext_marksvar}[B]}")
    eval "${wstext_posvar}=$b_pos"
    wstext-upd
}

zle -N wsblock-qk
bindkey -M wskeys "^Qk" wsblock-qk
bindkey -M wskeys "^QK" wsblock-qk
wsblock-qk() {
    local k_pos=$(eval "echo \${${wstext_marksvar}[K]}")
    eval "${wstext_posvar}=$k_pos"
    wstext-upd
}


