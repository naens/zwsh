# prepare dialogs
wsdialog-prepare() {
    for dialog in wsdialog_modes; do
        local dname="wsdialog_"$dialog
        local dfn="wsdialog-"$dialog
        local mname=$dname"_line"
        bindkey -N $mname wsline
        zle -N $dname"_accept"
        bindkey -M $mname "^M" $dname"_accept"
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
    done
}

# !!!cursor & highlight state save/restore by caller!!!

# display dialog
wsdialog-run() {
    local dialog=$1
    local msgvar=wsdialog_${dialog}_msg
    local msg=$(eval echo \$$msgvar)

    zle end-of-line
    wsdialog_start=$CURSOR
    wsdialog_init_highlight=$region_highlight

    local line1=$msgvar
    local line2=" *RETURN* done | *Backspace* or *^H* erase left"
    local line3="  *^U* cancel  |       *Del* or *^G* erase char"
    wsdialog-parse-format $line1
    local line1_txt=$wsdialog_pft
    wsdialog_line1_fmt=$wsdialog_pff
    wsdialog-parse-format $line2
    local line2_txt=$wsdialog_pft
    wsdialog_line2_fmt=$wsdialog_pff
    wsdialog-parse-format $line3
    local line3_txt=$wsdialog_pft
    wsdialog_line3_fmt=$wsdialog_pff

    wsdialog-parse-format $text_form
    LBUFFER+=$'\n'$line1_txt$'\n'$line2_txt$'\n'$line3_txt
    wsdialog_line2_start=$(( $wsdialog_start + ${#line1_txt} + 1 ))
    wsdialog_line3_start=$(( $wsdialog_line2_start + ${#line2_txt} + 1 ))
    wsdialog_prompt_begin=$(( $wskw_start + ${#line1_txt} + 1 ))
    wsdialog_prompt_end=$(( ${#BUFFER} - $wsdialog_prompt_begin ))
    wsdialog_end=$(( $wskw_prompt_end - ${#line2_txt} - ${#line3_txt} - 2 ))
    CURSOR=$wskw_prompt_begin
    local cols=$(tput cols)
    wsline_maxlen=$(( $cols - ${#line1_txt} - 1))
    wsline-init "wsdialog-hlupd"
    local mname=$dialog"_line"
    zle -K $mname
    wsdialog-hlupd
}

# put text of the argument in $wsdialog_pft, format in $wsdialog_pff
# format is made of 3 items: begin, end and type (bold/standout...)
# switches: '*' bold, '#' standout, '_' underline
wsdialod-parse-format() {
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
    local begin=$2
    local end=$3
    local type=$4
    local from=$(( $begin + $shift ))
    local to=$(( $end + $shift ))
    region_highlight+=($from $to $type)
}

wsdialog-hlupd() {
    region_highlight=$wsdialog_init_highlight
    wsdialog-apply-format $wsdialog_start $wsdialog_line1_fmt
    wsdialog-apply-format $wsdialog_line2_start $wsdialog_line2_fmt
    wsdialog-apply-format $wsdialog_line3_start $wsdialog_line3_fmt
}

# remove dialog l4 and restore cursor
wsdialog-rml4() {
    local dialog=$1
}
