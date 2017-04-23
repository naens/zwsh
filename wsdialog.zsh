# prepare dialogs
wsdialog-prepare() {
    for dialog in ${wsdialog_modes[@]}; do
        local dname="wsdialog_"$dialog
        local dfn="wsdialog-"$dialog
        local mname=$dname"_line"
        bindkey -N $mname wsline
        zle -N ${dfn}"-acceptfn"
        bindkey -M $mname "^M" ${dfn}-acceptfn
        zle -N $dname"_restore"
        bindkey -M $mname "^U" $dname"_restore"
        local modesvar=$dname"_modes"
        local modes=$(eval echo \$$modesvar)
        for l4mode in $modes; do
            local l4mname=$l4mode"_l4"
            bindkey -N $l4mname
            zle -N "${dfn}-rml4"
            bindkey -M $l4mname "^U" "${dfn}-rml4"
        done
        eval ${dfn}-run() { wsdialog-run $dialog }
        eval ${dfn}-rml4() { wsdialog-rml4 $dialog }
        eval ${dfn}-acceptfn() { wsdialog-acceptfn $dialog }
    done
}


# removes line 1-3 and line4 if present
wsdialog-close() {
    local bufsz=${#BUFFER}
    local end=$((bufsz - wsdialog_end + 1))
echo s=$wsdialog_start ee=$wsdialog_end e=$end sz=$bufsz > /dev/pts/3
#    BUFFER=$BUFFER[1,wsdialog_start]$BUFFER[end,bufsz]
    local str1=$BUFFER[1,wsdialog_start]
    local str2=$BUFFER[end,bufsz]
    echo str1=$str1 str2=$str2 > /dev/pts/3
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

# ask caller what to do
wsdialog-acceptfn() {
    local dialog=$1
    local do_accept=wsdialog-${dialog}-accept
    local textvar=wsline_wsdialog_$dialog
    wsdialog_text="${(P)textvar}"

    $do_accept     # defines $wsdialog_l4mode
    if [[ -n $wsdialog_l4mode ]]; then
    # chose mode, enter l4mode
    else    
        wsline-finalize $dialog

        #restore text, cursor and region_highlight
        wsdialog-close
        CURSOR=wsdialog_savecurs
        region_highlight=$wsdialog_init_highlight

        zle -K $wsdialog_savemode

        # unset variables
        wsdialog-unsetvars
    fi
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
    wsdialog_start=$CURSOR
    wsdialog_init_highlight=$region_highlight

    local line1=$msg
    local line2=" *RETURN* done | *Backspace* or *^H* erase left"
    local line3="  *^U* cancel  |       *Del* or *^G* erase char"
    wsdialog-parse-format $line1
    local line1_txt=$wsdialog_pft
    wsdialog_line1_fmt=($wsdialog_pff)
    wsdialog-parse-format $line2
    local line2_txt=$wsdialog_pft
    wsdialog_line2_fmt=($wsdialog_pff)
    wsdialog-parse-format $line3
    local line3_txt=$wsdialog_pft
    wsdialog_line3_fmt=($wsdialog_pff)
    
    LBUFFER+=$'\n'$line1_txt$'\n'$line2_txt$'\n'$line3_txt
    wsdialog_line2_start=$(( $wsdialog_start + ${#line1_txt} + 1 ))
    wsdialog_line3_start=$(( $wsdialog_line2_start + ${#line2_txt} + 1 ))
    wsdialog_prompt_begin=$(( $wsdialog_start + ${#line1_txt} + 1 ))
    wsdialog_prompt_end=$(( ${#BUFFER} - $wsdialog_prompt_begin ))
    wsdialog_end=$(( $wsdialog_prompt_end - ${#line2_txt} - ${#line3_txt} - 2 ))
    CURSOR=$wsdialog_prompt_begin
    local cols=$(tput cols)
    wsline_maxlen=$(( $cols - ${#line1_txt} - 1))
    wsline-init wsdialog-hlupd wsdialog_$dialog
    local mname=wsdialog_$dialog"_line"
    zle -K $mname
}

# put text of the argument in $wsdialog_pft, format in $wsdialog_pff
# format is made of 3 items: begin, end and type (bold/standout...)
# switches: '*' bold, '#' standout, '_' underline
wsdialog-parse-format() {
    unset wsdialog_pft
    unset wsdialog_pff
    local str=$1
    local bold=""
    local standout=""	
    local underline=""
    local count=1
    local ti=0
    for i in {1..${#str}}; do
        local c=$str[i]
        if [[ "$c" == "*" ]]; then
            if [[ -z $bold ]]; then
                bold=$ti
            else
                wsdialog_pff[count]="$bold $ti bold"
                count=$(( count + 1 ))
                bold=""
            fi
        elif [[ "$c" == "#" ]]; then
            if [[ -z $standout ]]; then
                standout=$ti
            else
                wsdialog_pff[count]="$standout $ti standout"
                count=$(( count + 1 ))
                standout=""
            fi
        elif [[ "$c" == "_" ]]; then
            if [[ -z $underline ]]; then
                underline=$ti
            else
                wsdialog_pff[count]="$underline $ti underline"
                count=$(( count + 1 ))
                underline=""
            fi
        else
            wsdialog_pft+="$c"
            ti=$(( ti + 1 ))
        fi
    done
}


wsdialog-apply-format() {
    local shift=$1
    shift
    local fmt=$1
    while [[ -n $fmt ]]; do
        local a=("${(@s/ /)fmt}")
        local begin=$a[1]
        local end=$a[2]
        local type=$a[3]
        local from=$(( $begin + $shift ))
        local to=$(( $end + $shift ))
        local ff=($from $to $type)
        region_highlight+=$ff
        shift
        fmt=$1
    done
}

wsdialog-hlupd() {
    region_highlight=$wsdialog_init_highlight
    wsdialog-apply-format $wsdialog_start $wsdialog_line1_fmt
    local l2s=$((wsdialog_line2_start + wsline_len + 1))
    local l3s=$((wsdialog_line3_start + wsline_len + 1))
    wsdialog-apply-format $l2s $wsdialog_line2_fmt
    wsdialog-apply-format $l3s $wsdialog_line3_fmt
}

# remove dialog l4 and restore cursor
wsdialog-rml4() {
    local dialog=$1
}
