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
    eval "wsline_${name}_begin=$begin"
    eval "wsline_${name}_len=$len"
    eval "wsline_${name}_text=''"
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
#    ws-debug WSLINE_INIT: name=$name
#    ws-debug WSLINE_INIT"{1}": CURSOR=$CURSOR begin=$begin len=$len
    ws-insert-xtimes $begin $len " "
#    ws-debug WSLINE_INIT"{2}": CURSOR=$CURSOR
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
}

wsline-exit() {
    local name=$1
    ws-debug WSLINE_EXIT name="\"$name\""

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
            ws-debug WSLINE_GET_DISPLAY_TEXT: code=$code n=$n
            result+="^"$(printf '\x'$n)
        else
            result+=$c
        fi
        i=$((i+1))
    done
    ws-debug WSLINE_GET_DISPLAY_TEXT: "display: \"$result\"" highlight="($wsline_highlight)"
    echo "$result"
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
    read dtextpos dtlen m1 m2 <<< $(wsline-convert-display-pos \
    	"$name" "$text" "($textpos $tlen $wsline_bpos $wsline_kpos)" )
    ws-debug WSLINE_UPDATE dtextpos=$dtextpos dtlen=$dtlen m1=$m1 m2=$m2

    # TODO: convert highlight to screen positions, display
    #       !! when leaving: remove all highlighting!

    local oldscroll=${(P)scrollposvar}
    local scrollpos=$(ws-get-scrollpos $dtlen $flen $dtextpos $oldscroll)
    eval "$scrollposvar=$scrollpos"

#    ws-debug WSLINE_UPDATE: name=$name begin=$begin text=\"$text\"
#    ws-debug WSLINE_UPDATE: tlen=$tlen flen=$flen textpos=$textpos oldscroll=$oldscroll scrollpos=$scrollpos
    local cursorpos=$((begin+dtextpos-scrollpos))
    BUFFER[begin+1,begin+flen]="$dtext[1+scrollpos,flen+scrollpos]"
    ws-insert-xtimes $((begin+dtlen-scrollpos)) $((scrollpos+flen-dtlen)) "-"


    # display <B>, <K> + cursor skip <B>/<K>
    ws-debug WSLINE_UPDATE: rhl="$region_highlight"
    ws-debug WSLINE_UPDATE: ohl="$wsline_orighl"
    ws-debug WSLINE_UPDATE: showbk=$wsline_showbk blockvis=$wsline_blockvis
    region_highlight=( "${wsline_orighl[@]}" )
    if [[ "$wsline_showbk" = "true" ]]; then
        # TODO: find positions for <B> and <K>
        if [[ -n "$m1" ]]; then
            local m1end=$((begin+m1-scrollpos))
            region_highlight+=("$((m1end-3)) $m1end standout")
        fi
        if [[ -n "$m2" ]]; then
            local m2end=$((begin+m2-scrollpos))
            region_highlight+=("$((m2end-3)) $m2end standout")
        fi
    elif [[ "$wsline_blockvis" = "true" ]]; then
        local dbpos=$((begin+m1-scrollpos))
        local dkpos=$((begin+m2-scrollpos))
        ws-debug WSLINE_UPDATE: dbpos=$dbpos dkpos=$dkpos
        region_highlight+=("$dbpos $dkpos standout")
    fi
    ws-debug WSLINE_UPDATE: region_highlight="$region_highlight"

    # TODO: display ^ characters as *bold* (not standout)

    #TODO: * exchange with buffer: ^U and ^KB/^KK and back
    #TODO: * length: with control characters and <B>/<K> elements
#    ws-debug cursorpos=$cursorpos
    CURSOR=$((begin+dtextpos-scrollpos))
}
