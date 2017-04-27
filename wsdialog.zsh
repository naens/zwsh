# prepare dialogs
wsdialog-prepare() {
    for dialog in ${wsdialog_modes[@]}; do
        local dname="wsdialog_"$dialog
        local dfn="wsdialog_"$dialog
        local mname=$dname"_line"
        bindkey -N $mname wsline
#        zle -N ${dfn}"-acceptfn"
#        bindkey -M $mname "^M" ${dfn}-acceptfn
#        zle -N ${dfn}-restore
#        bindkey -M $mname "^U" ${dfn}-restore
        local modesvar=$dname"_modes"
        local modes=(${(P)modesvar})
        for l4mode in $modes; do
            local l4afnv=${dname}_${l4mode}_accept
            local l4afn=${(P)l4afnv}
            local l4mname=${dname}_${l4mode}_l4
            if [[ -n $l4afn ]]; then
                bindkey -N $l4mname wsline
            else
                bindkey -N $l4mname
            fi
            bindkey -N $l4mname
            echo WSDIALOG_PREPARE: create l4mode: \"$l4mode\" > $debugfile
            zle -N "${dfn}-rml4"
            bindkey -M $l4mname "^U" "${dfn}-rml4"
        done
        eval "${dfn}-run() { wsdialog-run $dialog }"
        eval "${dfn}-rml4() { wsdialog-rml4 $dialog }"
        eval "${dfn}-acceptfn() { wsdialog-acceptfn $dialog }"
        eval "${dfn}-cancelfn() { wsdialog-cancelfn $dialog }"
        wsline-prepare $dname
    done
}


# removes line 1-3 and line4 if present
wsdialog-close() {
    local bufsz=${#BUFFER}
    local end=$((bufsz - wsdialog_end + 1))
    local str1=$BUFFER[1,wsdialog_start-1]
    local str2=$BUFFER[end,bufsz]
    BUFFER=$str1$str2
}

wsdialog-unsetvars() {
    unset wsdialog_savecurs
    unset wsdialog_start
    unset wsdialog_init_highlight
    unset wsdialog_end
    unset wsdialog_text
    unset wsdialog_line1_fmt
    unset wsdialog_line2_fmt
    unset wsdialog_line3_fmt
    unset wsdialog_prompt_bigin
    unset wsdialog_prompt_end
    unset wsdialog_line2_start
    unset wsdialog_line3_start
    unset wsdialog_maxlen
    unset wsdialog_savemode
}

# display line4 (replacing the old one if needed) and enter l4 mode
wsdialog-l4run() {
    local dialog=$1
    local l4mode=$2
    local end=$(( ${#BUFFER} - $wsdialog_end ))
    echo WSDIALOG_L4RUN: dialog=$dialog l4mode=$l4mode end=$end > $debugfile

    # remove old line4 if needed
    BUFFER[wsdialog_line4_start+1,end]=""

    # display line4 and move cursor
    local l4rtv=wsdialog_${dialog}_${l4mode}_msg
    local l4rt=${(P)l4rtv}
    ws-insert-formatted-at $wsdialog_line4_start $l4rt
    local l4len=${#ws_pft}
    CURSOR=$((wsdialog_line4_start + l4len))
    echo WSDIALOG_L4RUN: inserting at $wsdialog_line4_start \"$l4rt\" > $debugfile
    
    # enter l4mode
    local l4afnvar=wsdialog_${dialog}_${l4mode}_accept
    local l4acceptfn=${(P)l4afnvar}
    local l4mname=wsdialog_${dialog}_${l4mode}_l4
    if [[ -n $l4acceptfn ]]; then
        local cols=$(tput cols)
        declare wsline_${l4mname}_maxlen=$(( $cols - ${#line1_txt} - 1))
        wsline-init $l4mname
    fi
    zle -K $l4mname
}

# ask caller what to do
wsdialog-acceptfn() {
    local dialog=$1
    local do_accept=wsdialog_${dialog}-accept
    local do_restore=wsdialog_${dialog}-restore
    local textvar=wsline_wsdialog_${dialog}_text
    wsdialog_text="${(P)textvar}"
    echo "WSDIALOG_ACCEPTFN" var=$textvar text=\"$wsdialog_text\"> $debugfile
    $do_accept     # defines $wsdialog_l4mode
    if [[ -n $wsdialog_l4mode ]]; then
        wsdialog-l4run $dialog $wsdialog_l4mode
        # chose mode, enter l4mode
        echo abcd > /dev/null

        #TODO line4 mode: exists "accept" => input l4mode
        #                 otherwise, readkey mode
    else    
        wsline-finalize $dialog

        #restore text, cursor and region_highlight
        wsdialog-close
        CURSOR=wsdialog_savecurs
        region_highlight=$wsdialog_init_highlight

        zle -K $wsdialog_savemode
        $do_restore

        # unset variables
        wsdialog-unsetvars
    fi
}

# close everything and call restore
wsdialog-cancelfn() {
    local dialog=$1
    local do_restore=wsdialog_${dialog}-restore

    unset wsdialog_text
    wsline-finalize $dialog

    #restore text, cursor and region_highlight
    wsdialog-close
    CURSOR=wsdialog_savecurs
    region_highlight=$wsdialog_init_highlight

    zle -K $wsdialog_savemode
    $do_restore

    # unset variables
    wsdialog-unsetvars
}

# !!!cursor & highlight state save/restore by caller!!!

# display dialog
wsdialog-run() {
    local dialog=$1
    local msgvar=wsdialog_${dialog}_msg
    local msg=${(P)msgvar}

    wsdialog_savecurs=$CURSOR
    wsdialog_savemode=$KEYMAP

    zle end-of-line
    LBUFFER+=$'\n'
    wsdialog_start=$CURSOR
    wsdialog_init_highlight=$region_highlight

    local line1=$msg$'\n'
    local line2=" *RETURN* done | *Backspace* or *^H* erase left"$'\n'
    local line3="  *^U* cancel  |       *Del* or *^G* erase char"$'\n'

    ws-insert-formatted-at $CURSOR $line1
    wsdialog_line1_len=${#ws_pft}
    wsdialog_line1_fmt=($ws_pff)

    wsdialog_line2_start=$(( wsdialog_start + wsdialog_line1_len ))
    ws-insert-formatted-at $wsdialog_line2_start $line2
    wsdialog_line2_len=${#ws_pft}
    wsdialog_line2_fmt=($ws_pff)

    wsdialog_line3_start=$(( wsdialog_line2_start + wsdialog_line2_len ))
    ws-insert-formatted-at $wsdialog_line3_start $line3
    wsdialog_line3_len=${#ws_pft}
    wsdialog_line3_fmt=($ws_pff)

    wsdialog_line4_start=$(( wsdialog_line3_start + wsdialog_line3_len ))
    wsdialog_prompt_begin=$(( $wsdialog_line2_start - 1 ))
    wsdialog_prompt_end=$(( ${#BUFFER} - $wsdialog_prompt_begin ))
    wsdialog_end=$(( ${#BUFFER} - wsdialog_line4_start ))
    CURSOR=$wsdialog_prompt_begin

    # prepare wsline and enter
    local cols=$(tput cols)
    declare wsline_wsdialog_${dialog}_maxlen=$(( $cols - ${#line1_txt} - 1))
    wsline-init wsdialog_$dialog wsdialog-upd
    local mname=wsdialog_$dialog"_line"
    zle -K $mname
}

wsdialog-upd() {
    region_highlight=$wsdialog_init_highlight
    ws-apply-format $wsdialog_start $wsdialog_line1_fmt
    wsdialog_line2_start=$((wsdialog_start + wsdialog_line1_len + wsline_len))
    wsdialog_line3_start=$((wsdialog_line2_start + wsdialog_line2_len))
    wsdialog_line4_start=$((wsdialog_line3_start + wsdialog_line3_len))
    ws-apply-format $wsdialog_line2_start $wsdialog_line2_fmt
    ws-apply-format $wsdialog_line3_start $wsdialog_line3_fmt
}

# remove dialog l4 and restore cursor
wsdialog-rml4() {
    local dialog=$1
}
