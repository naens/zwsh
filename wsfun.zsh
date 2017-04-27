# file contains global variables and functions that can be used anywhere
ws_echo=$(sh -c 'which echo')

ws-do-bold() {
    i=$(( ${#region_highlight} + 1 ))
    base=$1
    y=0
    shift
    for x in $@
    do
        if [[ $y -eq 0 ]]; then
            v1=$(( $base + $x ))
            y=1
        else
            v2=$(( $base + $x ))
            y=0
	    region_highlight[$i]=("$v1 $v2 bold")
	    i=$(( $i + 1 ))
        fi
    done
}

ws-pos() {
    local from
    local to
    if [[ -n $1 ]]; then
        from=$(( $1 + 1 ))
    else
        from=1
    fi
    if [[ -n $2 ]]; then
        to=$(( $2 + 1 ))
    else
        to=$(( ${#BUFFER} + 1 ))
    fi
    local curs=$(( $CURSOR + 1 ))
    if [[ $from -le $curs && $curs -le $to ]]; then
        ws_row=1
        ws_col=1
        for i in {$from..$to}; do
            if [[ $i -eq $curs ]]; then
                break
            fi
            if [[ $BUFFER[$i] == $'\n' ]]; then
                ws_row=$(( $ws_row + 1 ))
                ws_col=1
            elif [[ $BUFFER[$i] == $'\t' ]]; then
                local rest=$(( ($ws_col - 1) % 8 ))
                ws_col=$(( $ws_col + 8 - $rest))
            elif [[ -n $kb && -z $kk && $i -eq $(( $kb + 1 )) ]]; then
                ws_col=$(( $ws_col - 2 ))                
            else
                ws_col=$(( $ws_col + 1 ))
            fi
        done
    fi
}


# put text of the argument in $wsdialog_pft, format in $wsdialog_pff
# format is made of 3 items: begin, end and type (bold/standout...)
# switches: '*' bold, '#' standout, '_' underline
ws-parse-format() {
    unset ws_pft
    unset ws_pff
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
                ws_pff[count]="$bold $ti bold"
                count=$(( count + 1 ))
                bold=""
            fi
        elif [[ "$c" == "#" ]]; then
            if [[ -z $standout ]]; then
                standout=$ti
            else
                ws_pff[count]="$standout $ti standout"
                count=$(( count + 1 ))
                standout=""
            fi
        elif [[ "$c" == "_" ]]; then
            if [[ -z $underline ]]; then
                underline=$ti
            else
                ws_pff[count]="$underline $ti underline"
                count=$(( count + 1 ))
                underline=""
            fi
        else
            ws_pft+="$c"
            ti=$(( ti + 1 ))
        fi
    done
}

ws-apply-format() {
    local pos=$1
    shift
    local fmt=$1
    while [[ -n $fmt ]]; do
        local a=("${(@s/ /)fmt}")
        local begin=$a[1]
        local end=$a[2]
        local type=$a[3]
        local from=$(( $pos + $begin ))
        local to=$(( $pos + $end ))
        local ff=($from $to $type)
        region_highlight+=$ff
        shift
        fmt=$1
    done
}

ws-insert-text-at() {
    local pos=$1
    local text="$2"
    local len=${#text}
    local curs=$CURSOR
    if [[ $pos -eq 0 ]]; then
        BUFFER=$text$BUFFER
    else
        local bufsz=${#BUFFER}
        BUFFER=$BUFFER[1,pos]$text$BUFFER[pos+1,bufsz]
    fi
    if [[ $pos -gt $CURSOR ]]; then
        CURSOR=$(( $curs + $pos ))
    fi
}

# insert formatted text at $pos and overwrites $ws_pff and $ws_pft
ws-insert-formatted-at() {
    local pos=$1
    local ft="$2"
    ws-parse-format "$ft"
    ws-insert-text-at $pos "$ws_pft"
    ws-apply-format $pos $ws_pff
    echo "pos=$pos ws_pft=#$ws_pft# ws_pff=#$ws_pff#" > $debugfile
}