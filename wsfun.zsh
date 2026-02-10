# file contains global variables and functions that can be used anywhere
ws_echo=$(sh -c 'which echo')

not() {
    if "$1"; then
        echo false
    else
        echo true
    fi
}

skip() {}

ws-do-bold() {
    i=$(( ${#region_highlight} + 1 ))
    base=$1
    y=0
    shift
    for x in $@; do
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

# get screen dimensions in $ws_rows and $ws_cols
ws-size() {
    ws_rows=$(tput lines)
    ws_cols=$(tput cols)
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
    if [[ $pos -le $CURSOR ]]; then
        CURSOR=$(( $curs + $len ))
    fi
}

# insert formatted text at $pos and overwrites $ws_pff and $ws_pft
ws-insert-formatted-at() {
    local pos=$1
    local ft="$2"
    ws-parse-format "$ft"
    ws-insert-text-at $pos "$ws_pft"
    ws-apply-format $pos $ws_pff
}

ws-find-right() {
    local pos=$(ws-max 1 $1)
    local pattern="$2"
    local text="$3"
    local search_part="$text[pos,${#text}]"
    local rest=${search_part%%$~pattern*}
    if [[ "$rest" = "$search_part" ]]; then
        echo -1
    else
        local res=$((pos+${#rest}))
        echo $res
    fi
}

ws-find-left() {
    local pos=$(ws-max 1 $1)
    local pattern="$2"
    local text="$3"
    local search_part="$text[1,pos-1]"
    local rest=${search_part%$~pattern*}
    if [[ "$rest" = "$search_part" ]]; then
        echo -1
    else
        res=$((${#rest}+1))
        echo $res
    fi
}

ws-defvar() {
    local varname=$1
    local text="$2"
    eval $varname=\'${text:gs/\'/\'\"\'\"\'}\'
}

ws-printvar() {
    local var=$1
    echo "${(P)var}"
}

# debug
ws-debug() {
    local debug_string="$@"
    if [[ -n "$ws_debugfile" ]]; then
        if [[ ! -w "$ws_debugfile" ]]; then
            unset ws_debugfile
        else
            echo "$debug_string" > "$ws_debugfile"
        fi
    fi
}

# switch debug on and off from command line
zwdbg() {
    local param=$1
    local debvar="ws_debugfile"
    local debugfn="$srcdir/wsdebug-tty.zsh"
    if [[ -z "$param" ]]; then
        if [[ ! -f "$debugfn" ]]; then
            param=on
            echo setting zw debug on
        else
            local debug_file=$(cat "$debugfn")
            if [[ "$debug_file" = "$debvar=/dev/null" ]]; then
                param=on
                echo setting zw debug on
            else
                echo debug_file: \""$debug_file"\"
                param=off
                echo setting zw debug off
            fi
        fi
    fi
    local outfn=""
    if [[ "$param" = on ]]; then
        outfn=$(tty)
    elif [[ "$param" = off ]]; then
        outfn=/dev/null
    else
        echo usage $0 '<on|off>'
        return
    fi
    echo "$debvar=$outfn" > "$debugfn"
#    eval "$debvar=$outfn"
    source "$debugfn"
}


ws-min() {
    if [[ "$1" -lt "$2" ]]; then
        echo "$1"
    else
        echo "$2"
    fi
}

ws-max() {
    if [[ "$1" -gt "$2" ]]; then
        echo "$1"
    else
        echo "$2"
    fi
}

ws-lim() {
    local n=$1
    local min=$2
    local max=$3
    if [[ $n -le $min ]]; then
        echo $min
    elif [[ $n -ge $max ]]; then
        echo $max
    else
        echo $n
    fi
}

# repeat insert $3 $2 times at $1 in BUFFER
ws-insert-xtimes() {
    local pos=$1
    local i=$2
    local string=$3
    while [[ $i -gt 0 ]]; do
        i=$((i-1))
        ws-insert-text-at $pos "$string"
    done
    # CURSOR is moved by the ws-insert-text-at function forward
}

# update scroll position given:
#  * text length
#  * field length
#  * position
#  * old scroll position
# returns resutl as echo
ws-get-scrollpos() {
    local t=$1
    local f=$2
    local p=$3
    local s=$4
    if [[ $t -lt $f ]]; then
        r=0
    else
        maxscroll=$((p>t-f?t-f+1:p))
        minscroll=$((p>=f?p-f+1:0))
        r=$((s<minscroll?minscroll:s>maxscroll?maxscroll:s))
    fi
    echo $r
}

ws-uc() {
    echo $(tr "[:lower:]" "[:upper:]" <<< "$1")
}
