# prepare dialogs
wsdialog-add() {
    local dialog=$1
    local mname=wsdialog_${dialog}_line
#    ws-debug WSDIALOG_ADD: \"$dialog\"
    local modesvar=wsdialog_${dialog}_modes
    local modes=(${(P)modesvar})
    for l4mode in $modes; do
        local l4mname=wsdialog_${dialog}_${l4mode}_l4
        bindkey -N "$l4mname"
#        ws-debug WSDIALOG_ADD: create l4mode: \"$l4mname\"

        # bind cancel line4 function
        zle -N wsdialog_${dialog}-ret-dial
        bindkey -M $l4mname "^U" "wsdialog_${dialog}-ret-dial"
        bindkey -M $l4mname "^M" "wsdialog_${dialog}-ret-dial"

        # bind user defined keys
        local funcsvar=wsdialog_${dialog}_${l4mode}_funcs
        declare -A funcs
        funcs=(${(@Pkv)funcsvar})
        for key func in "${(@kv)funcs}"; do
            local funname=wsdialog_${dialog}_${l4mode}_${func}
            zle -N $funname
            bindkey -M $l4mname $key $funname
            eval "$funname() { wsdialog-l4keyfn $dialog $func }"
        done
    done
    eval "wsdialog-${dialog}-run() { wsdialog-run $dialog }"
    eval "wsdialog_${dialog}-ret-dial() { wsdialog-ret-dial $dialog }"
    eval "wsline-wsdialog_${dialog}-accept() { wsdialog-acceptfn $dialog }"
    eval "wsline-wsdialog_${dialog}-cancel() { wsdialog-cancelfn $dialog }"
}

wsdialog-l4keyfn() {
    local dialog=$1
    local l4keyfn=$2

    $l4keyfn    # defines $wsdialog_l4mode
#    ws-debug WSDIALOG_L4KEYFN: dialog=$dialog l4keyfn=$l4keyfn m=$wsdialog_l4mode
    if [[ -z "$wsdialog_l4mode" ]]; then
        wsdialog-ret-dial $dialog
    elif [[ "$wsdialog_l4mode" == "<accept>" ]]; then
        wsdialog-close $dialog "OK"
    elif [[ "$wsdialog_l4mode" == "<cancel>" ]]; then
        unset wsdialog_text
        wsdialog-close $dialog "NO"
    else
        wsdialog-rml4 $dialog
#        ws-debug WSDIALOG_L4KEYFN: l4mode=$wsdialog_l4mode
        wsdialog-l4run $dialog $wsdialog_l4mode
    fi
}

# removes line 1-3 and line4 if present
wsdialog-del() {
    local bufsz=${#BUFFER}
    local end=$((wsdialog_start+wsdialog_len+wsdialog_l4len))
    local str1=$BUFFER[1,wsdialog_start-1]
    local str2=$BUFFER[end,bufsz]
    BUFFER=$str1$str2
}

# exit dialog and restore variables
wsdialog-close() {
    local dialog=$1
    # status in $2
    local do_restore=wsdialog_${dialog}_restore
    wsline-exit "$dialog"

    #restore text, cursor and region_highlight
    wsdialog-del
    CURSOR=$wsdialog_savecurs
    region_highlight=$wsdialog_init_highlight

    wstext_textvar=$wsdialog_oldtextvar
    wstext_updfnvar=$wsdialog_oldupdfnvar
    wstext_posvar=$wsdialog_oldposvar
    zle -K $wsdialog_savemode

    # unset variables
    wsdialog-unsetvars

    # call restore function
    ${(P)do_restore} $2
}

wsdialog-unsetvars() {
    unset wsdialog_savecurs
    unset wsdialog_start
    unset wsdialog_init_highlight
    unset wsdialog_text
    unset wsdialog_maxlen
    unset wsdialog_savemode
    unset wsdialog_len
    unset wsdialog_l4len
    unset wsdialog_l4start
    unset wsdialog_oldtextvar
    unset wsdialog_oldupdfnvar
    unset wsdialog_oldposvar
}

# display line4 and enter l4 mode
wsdialog-l4run() {
    local dialog=$1
    local l4mode=$2
    local end=$((wsdialog_start+wsdialog_len))
#    ws-debug WSDIALOG_L4RUN: l4mode=$l4mode

    wsdialog_prel4save_cursor=$CURSOR
    wsdialog_prel4save_highlight=($region_highlight)
#    ws-debug WSDIALOG_L4RUN: save prel4-highlight=$region_highlight

    # display line4 and move cursor
    local l4rtv=wsdialog_${dialog}_${l4mode}_msg
    local l4rt="${(P)l4rtv}"
    ws-insert-formatted-at $wsdialog_l4start "$l4rt"
    wsdialog_l4len=${#ws_pft}
    CURSOR=$((wsdialog_l4start+wsdialog_l4len))

    # enter l4mode
    local l4mname=wsdialog_${dialog}_${l4mode}_l4
    zle -K "$l4mname"
}

# ask caller what to do
wsdialog-acceptfn() {
    local dialog=$1
    local do_accept=wsdialog_${dialog}_accept
    local textvar=wsline_wsdialog_${dialog}_text
#    ws-debug WSDIALOG_ACCEPTFN: dialog=$dialog
    wsdialog_text="${(P)textvar}"
    ${(P)do_accept}     # defines $wsdialog_l4mode
    if [[ -n $wsdialog_l4mode ]]; then
        wsdialog-l4run $dialog $wsdialog_l4mode
    else
        wsdialog-close $dialog "OK"
    fi
}

# close everything and call restore
wsdialog-cancelfn() {
    local dialog=$1
#    ws-debug WSDIALOG_CANCELFN: dialog=$dialog

    unset wsdialog_text
    wsdialog-close $dialog "NO"
}

# !!!cursor & highlight state save/restore by caller!!!

# display dialog
wsdialog-run() {
    local dialog=$1
    local msgvar=wsdialog_${dialog}_msg
    local msg=${(P)msgvar}

    wsdialog_savecurs=$CURSOR
    wsdialog_savemode=$KEYMAP
    wsdialog_oldtextvar=$wstext_textvar
    wsdialog_oldupdfnvar=$wstext_updfnvar
    wsdialog_oldposvar=$wstext_posvar

    zle end-of-line
    LBUFFER+=$'\n'
    wsdialog_start=$CURSOR
    wsdialog_init_highlight=$region_highlight

    local line1=$msg
    local line2=" *RETURN* done | *Backspace* or *^H* erase left"$'\n'
    local line3="  *^U* cancel  |       *Del* or *^G* erase char"$'\n'

    ws-insert-formatted-at $CURSOR "$line1"
    l1len=${#ws_pft}
#    wsdialog_line1_fmt=($ws_pff)

    # insert wsline
    local cols=$(tput cols)
    local len=$((cols-l1len-1))
    wsline-init wsdialog_$dialog $CURSOR $len

    local l2start=$((wsdialog_start+l1len+len))
    ws-insert-formatted-at $l2start $'\n'"$line2"
    local l2len=${#ws_pft}
#    wsdialog_line2_fmt=($ws_pff)

    local l3start=$((l2start+l2len))
    ws-insert-formatted-at $l3start "$line3"
    local l3len=${#ws_pft}
#    wsdialog_line3_fmt=($ws_pff)
    wsdialog_len=$((l1len+len+1+l2len+l3len))

    wsdialog_l4start=$((l3start+l3len))
    wsdialog_l4len=0
    CURSOR=$((l2start-1))

    # enter wsline
    wsline-activate wsdialog_$dialog
}

# remove dialog l4
wsdialog-rml4() {
    local dialog=$1
#    ws-debug WSDIALOG_RML4: dialog=\"$dialog\"

    # remove old line4
    BUFFER[wsdialog_l4start+1,wsdialog_l4start+wsdialog_l4len+1]=""

    # restore region highlight
#    ws-debug WSDIALOG_RML4: prel4-highlight=$wsdialog_prel4save_highlight
    region_highlight=($wsdialog_prel4save_highlight)

    # restores dialog cursor
    CURSOR=$wsdialog_prel4save_cursor
}

# remove line4, restore state
wsdialog-ret-dial() {
    local dialog=$1
    wsdialog-rml4 $dialog

    # remove line4 marker
    unset wsdialog_l4mode

    wsline-activate wsdialog_$dialog
}
