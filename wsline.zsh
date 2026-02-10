# SINGLE LINE EDITING MODE
# ========================
# $wsline_maxlen=maximal length of the line
# keybindings to switch to other line, as well as ^M and Enter
# are by default disabled.
# if $wsline_maxlen is 0, then mute mode

bindkey -N wsline wskeys
bindkey -M wsline -r "^Ke"
bindkey -M wsline -r "^KE"
bindkey -M wsline -r "^Kd"
bindkey -M wsline -r "^KD"
bindkey -M wsline -r "^Ks"
bindkey -M wsline -r "^KS"
bindkey -M wsline -r "^Kx"
bindkey -M wsline -r "^KX"
bindkey -M wsline -r "^Km"
bindkey -M wsline -r "^KM"
bindkey -M wsline -r "^E"
bindkey -M wsline -r "^X"

# initialize mode and insert field at $begin in BUFFER
wsline-init() {
    local name=$1
    local begin=$2
    local len=$3
    local marksvar=$4
    local visvar=$5
    local text="$6"
    eval "wsline_${name}_begin=$begin"
    eval "wsline_${name}_len=$len"
    eval "wsline_${name}_text=$text"
    eval "wsline-${name}-update() { wsline-update $name }"
    eval "wsline_${name}_textpos=0"
    eval "wsline_${name}_caller_marksvar=$marksvar"
    eval "wsline_${name}_caller_visvar=$visvar"
    declare -gA wsline_${name}_marksvar

    local mode=wsline-${name}-mode
    bindkey -N $mode wsline
    if typeset -f wsline-${name}-accept > /dev/null; then
        zle -N wsline-${name}-accept
        bindkey -M $mode "^M" wsline-${name}-accept
    fi
    if typeset -f wsline-${name}-cancel > /dev/null; then
        zle -N wsline-${name}-cancel
        bindkey -M $mode "^U" wsline-${name}-cancel
        bindkey -M $mode "^Kq" wsline-${name}-cancel
        bindkey -M $mode "^KQ" wsline-${name}-cancel
    fi
    zle -N wsline-kc
    bindkey -M $mode "^Kc" wsline-kc
    bindkey -M $mode "^KC" wsline-kc
#    ws-debug WSLINE_INIT: name=$name
#    ws-debug WSLINE_INIT"{1}": CURSOR=$CURSOR begin=$begin len=$len
    ws-insert-xtimes $begin $len " "
#    ws-debug WSLINE_INIT"{2}": CURSOR=$CURSOR
}

# inserts block if defined from wsline_other_textvar
wsline-kc() {
    if [[ -n "$wsline_blockvis" ]]; then
        wsblock-kc
    else
        local obpos=$(eval "echo \${${wsline_other_marksvar}[B]}")
        local okpos=$(eval "echo \${${wsline_other_marksvar}[K]}")
        ws-debug WSLINE_KC: obpos=$obpos okpos=$okpos
        if [[ -n "$obpos" && -n "$okpos" && "$obpos" -lt "$okpos" ]]; then
            local text="${(P)wsline_other_textvar}"
            local block="$text[obpos+1,okpos]"
            ws-debug WSLINE_KC: inserting block="\"$block\""
            wstext-insert "$block"
        fi
    fi
}

wsline-add-key() {
    local mode=$1
    local key="$2"
    local fun="$3"
    zle -N $fun
    bindkey -M $mode "$key" "$fun"
}

# cursor on wsline, text on first position, switch to mode
wsline-activate() {
    local name=$1

    wsline_other_textvar="$wstext_textvar"
    wsline_other_marksvar="$wstext_marksvar"

   # enter new state
    wstext_textvar=wsline_${name}_text
    wstext_updfnvar=wsline-${name}-update
    wstext_posvar=wsline_${name}_textpos
    wstext_marksvar=wsline_${name}_marksvar
    wstext_blockvisvar=wsline_${name}_blockvisvar
    wstext_blockcolmodevar=wsline_${name}_blockcolmodevar
    local beginvar=wsline_${name}_begin


#    ws-debug WSLINE_ACTIVATE: entering mode \"wsline-${name}-mode\", begin=${(P)beginvar}

    zle -K wsline-${name}-mode
#    eval "wsline_${name}_scrollpos=0"
    wsline_orighl=( "${region_highlight[@]}" )
    ws-debug WSLINE_ACTIVATE: rhl="$region_highlight"
    ws-debug WSLINE_ACTIVATE: ohl="$wsline_orighl"

    wsline-update $name
    ws-debug WSLINE_ACTIVATTE: other_textvar="$wsline_other_textvar" other_marksvar="$wsline_other_marksvar"
}

wsline-exit() {
    local name=$1
    ws-debug WSLINE_EXIT name=$name

    unset wsline_${name}_begin
    unset wsline_${name}_len
    unset wsline_${name}_text
    unset wsline_${name}_textpos
    unset wsline_${name}_update
    unset wsline_${name}_marksvar
    unset wsline_${name}_blockvisvar
    unset wsline_${name}_blockcolmodevar
    unset wstext_textvar
    unset wstext_updfnvar
    unset wstext_posvar
    unset wsline_bpos
    unset wsline_kpos
    unset wsline_blockvis
    unset wsline_showbk
    unset wsline_orighl
    unset wsline_ctrl_chrs
    unset wsline_other_textvar
    unset wsline_other_marksvar
}

# Function: wsline-updvars
#     Updates global variables relative to the state of the block.
#
wsline-updvars() {
    ws-debug WSLINE_UPDVARS marksvar="\"${wstext_marksvar}\""
    wsline_bpos=$(eval "echo \${${wstext_marksvar}[B]}")
    wsline_kpos=$(eval "echo \${${wstext_marksvar}[K]}")
    wsline_blockvis=${(P)wstext_blockvisvar}
    wsline_showbk=true
    if [[ -z "$wsline_blockvis" ]]; then
        wsline_bpos=""
        wsline_kpos=""
    	wsline_showbk=false
    elif [[ -n "$wsline_bpos" && -n "$wsline_kpos"
                 && "$wsline_bpos" -lt "$wsline_kpos" ]]; then
    	wsline_showbk=false
    fi
    ws-debug WSLINE_UPDVARS: bpos=$wsline_bpos kpos=$wsline_kpos \
    	vis=$wsline_blockvis showbk=$wsline_showbk
}

# Function: wsline-get-display-pos
#     Converts text to display representation:
#      - insert <B> and <K> where needed
#      - insert ^J instead of newline
#
# Parameters:
#     $1 - name
#     $2 - text
#
# Returns:
#     stdout - display version of the text
#
wsline-get-display-text() {
    local name="$1"
    local text="$2"
    ws-debug WSLINE_GET_DISPLAY_TEXT: "name=$name text=$text"
    local result=""
    local i=0
    local len=${#text}
    local a=$(printf "%d" "'A")
    while [[ $i -lt $((len+1)) ]]; do
        local c=$text[i+1]
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_bpos" ]]; then
            result+="<B>"
        fi
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_kpos" ]]; then
            result+="<K>"
        fi
        local code=$(printf "%d" "'$c")
        if [[ $code -ge 1 && $code -lt 32 ]]; then
            n=$(printf '%x' $((code+a-1)))
            result+="^"$(printf '\x'$n)
        else
            result+=$c
        fi
        i=$((i+1))
    done
    ws-debug WSLINE_GET_DISPLAY_TEXT: "display: \"$result\"" highlight="($wsline_highlight)"
    echo "$result"
}

# Function: wsline-get-ctrl-chrs
#     Returns the array of the positions of the control characters.
#
# Parameters:
#     $1 - text
#
# Returns:
#     stdout - the array of the positions of the control characters
#
wsline-get-ctrl-chrs() {
    local text="$1"
    local i=0
    local len=${#text}
    local dpos=0
    local ctrl_chrs=()
    while [[ $i -lt $((len+1)) ]]; do
        local c=$text[i+1]
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_bpos" ]]; then
            dpos=$((dpos+3))
        fi
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_kpos" ]]; then
            dpos=$((dpos+3))
        fi
        local code=$(printf "%d" "'$c")
        if [[ $code -ge 1 && $code -lt 32 ]]; then
            ctrl_chrs+=("$dpos")
            dpos=$((dpos+1))
        else
            result+=$c
        fi
        dpos=$((dpos+1))
        i=$((i+1))
    done
    ws-debug WSLINE_GET_CTRL_CHRS: ctrl_chrs=$ctrl_chrs
    echo "$ctrl_chrs"
}

# Function: wsline-display-pos
#     Converts positions in text to what they will be when displayed.
#     <B> and <K>, while not taking space in text, are of width 3 when dislpayed.
#     Control characters (^O, ^P) are counted as a single character in text,
#     but are two characters when displayed.
#     The newlines character is counted as '^J', because it is displayed
#     this way in wsline mode.
#
# Parameters:
#     $1 - text
#     $2 - sorted array of positions to convert
#
# Returns:
#     stdout - values of corresponding positions
#
wsline-convert-display-pos() {
    local name=$1
    local text=$2
    eval "pos_arr=$3"
    ws-debug WSLINE_CONVERT_DISLPAY_POS: "text=$text" $pos_arr[1] $pos_arr[2]
    
    local i=0
    local len=${#text}
    local dpos=0
#    local j=1
    local -a r=()
    local prevcode=0
    while [[ $i -le $len ]]; do
        local c=$text[i+1]
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_bpos" ]]; then
            dpos=$((dpos+3))
        fi
        if [[ "$wsline_showbk" = "true" && $i = "$wsline_kpos" ]]; then
            dpos=$((dpos+3))
        fi
        local code=$(printf "%d" "'$c")
        if [[ $prevcode -ge 1 && $prevcode -lt 32 ]]; then
            dpos=$((dpos+1))
        fi
#        ws-debug WSLINE_CONVERT_DISPLAY_POS: c=$c code=$code i=$i dpos=$dpos
        j=1
        while [[ $j -le ${#pos_arr} ]]; do
#        while [[ $j -le ${#pos_arr} && $pos_arr[j] -eq $i ]]; do
#            ws-debug WSLINE_CONVERT_DISPLAY_POS: $pos_arr[j] becomes $dpos
            if [[ $pos_arr[j] -eq $i ]]; then
                r[j]=$dpos
            fi
            j=$((j+1))
        done
        result+=$c
        i=$((i+1))
        dpos=$((dpos+1))
        prevcode=$code
    done
    ws-debug WSLINE_CONVERT_DISPLAY_POS: r=$r
    echo $r
}

wsline-highlight-bk() {
    local begin=$1
    local scrollpos=$2
    local fieldwidth=$3
    local markend=$4
#    ws-debug WSLINE_HIGHLIGHT_BK markend=$markend
    if [[ -z "$markend" ]]; then
        return
    fi
    if [[ $markend -lt $scrollpos ]]; then
        return
    fi 
    local markstart=$((markend-3))
    local fieldend=$((scrollpos+fieldwidth))
    if [[ $markstart -gt $fieldend ]]; then
        return
    fi
    if [[ $markstart -lt $scrollpos ]]; then
        markstart=$scrollpos
    fi
    if [[ $markend -gt $fieldend ]]; then
        markend=$fieldend
    fi
    local display_mark_start=$((begin+markstart))
    local display_mark_end=$((begin+markend))
    region_highlight+=("$display_mark_start $display_mark_end standout")
}

wsline-highlight-ctrl-chr() {
    local begin=$1
    local scrollpos=$2
    local fieldwidth=$3
    local dpos=$4
    local hlend=$((dpos+2))
    if [[ $hlend -lt $scrollpos ]]; then
        return
    fi 
    local fieldend=$((scrollpos+fieldwidth))
    if [[ $dpos -gt $fieldend ]]; then
        return
    fi
    if [[ $dpos -lt $scrollpos ]]; then
        dpos=$scrollpos
    fi
    if [[ $hlend -gt $fieldend ]]; then
        hlend=$fieldend
    fi
    local display_hlstart=$((begin+dpos))
    local display_hlend=$((begin+hlend))
    region_highlight+=("$display_hlstart $display_hlend bold")
}

# wsline variables:
#  - begin: position where the editable area begins
#  - len: length of the editable area
#  - text: variable containing the contents of the text

wsline-update() {
    local name=$1
    local textvar=wsline_${name}_text
    local text="${(P)textvar}"
    local tlen=${#text}
    local flenvar=wsline_${name}_len
    local flen=${(P)flenvar}
    local beginvar=wsline_${name}_begin
    local begin=${(P)beginvar}

    wsline-updvars
    
    local scrollposvar=wsline_${name}_scrollpos
    local posvar=wsline_${name}_textpos
    local textpos=${(P)posvar}

    # variables for display version of the text
    local dtext=$(wsline-get-display-text "$name" "$text")
    local ctrl_chrs=($(wsline-get-ctrl-chrs "$text"))
    read dtextpos dtlen m1 m2 <<< $(wsline-convert-display-pos \
    	"$name" "$text" "($textpos $tlen $wsline_bpos $wsline_kpos)" )
    if [[ -n "$m1" && -n "$m2" && "$m1" = "$m2" ]]; then
        m1=$((m1-3))
    fi

    local oldscroll=${(P)scrollposvar}
    local scrollpos=$(ws-get-scrollpos $dtlen $flen $dtextpos $oldscroll)
    eval "$scrollposvar=$scrollpos"

    local cursorpos=$((begin+dtextpos-scrollpos))
    BUFFER[begin+1,begin+flen]="$dtext[1+scrollpos,flen+scrollpos]"
    ws-insert-xtimes $((begin+dtlen-scrollpos)) $((scrollpos+flen-dtlen)) " "

    # display <B>, <K> + cursor skip <B>/<K>
    region_highlight=( "${wsline_orighl[@]}" )
    if [[ "$wsline_showbk" = "true" ]]; then
        wsline-highlight-bk $begin $scrollpos $flen $m1
        wsline-highlight-bk $begin $scrollpos $flen $m2
    elif [[ "$wsline_blockvis" = "true" ]]; then
        local dbpos=$((begin+m1-scrollpos))
        local dkpos=$((begin+m2-scrollpos))
        ws-debug WSLINE_UPDATE: dbpos=$dbpos dkpos=$dkpos
        region_highlight+=("$dbpos $dkpos standout")
    fi
#    ws-debug WSLINE_UPDATE: region_highlight="$region_highlight" 
    for dpos in $ctrl_chrs; do
        ws-debug WSLINE_UPDATE: highlight $dpos
        wsline-highlight-ctrl-chr $begin $scrollpos $flen $dpos
    done

    # FUTURE: exchange with buffer: ^U and ^KB/^KK and back
    # FUTURE: length: with control characters and <B>/<K> elements
    CURSOR=$((begin+dtextpos-scrollpos))
}
