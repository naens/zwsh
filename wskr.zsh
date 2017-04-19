# INSERT FILE AT CURSOR
# =====================

# file dialog
#+-------------------------------------------+
#|Document? <cursor>                         |
#| RETURN done | Backspace or ^H erase left  |
#|  ^U cancel  |             Del erase char  |
#|                                           |
#+-------------------------------------------+

# if not found, message (after line 4):
#+-------------------------------------------+
#|WordStar cannot find that document.        |
#|                                           |
#|Press Esc to continue.                     |
#|                                           |
#+-------------------------------------------+
# -> use line 4 for this

# OPEN FILE MODE: opens file and puts contents in a variable
#                 if does not succeed, contnts are empty
#                 variable name: $wskr_text
bindkey -N wskr-line wsline
bindkey -N wskr-eread

# display dialog, set kr=1
ws-krfn() {
    wskr_kmsave=$KEYMAP
    wskr_rh_save=$region_highlight
    unset wskr_text
    wskr_curs=$CURSOR
    zle end-of-line
    wskr_start=$CURSOR
    local line1="Document? "
    local line2=" RETURN done | Backspace or ^H erase left"
    local line3="  ^U cancel  |       Del or ^G erase char"
    LBUFFER+=$'\n'$line1$'\n'$line2$'\n'$line3
    wskr_fn_begin=$(( $wskr_start + ${#line1} + 1 ))
    wskr_fn_end=$(( ${#BUFFER} - $wskr_fn_begin ))
    wskr_end=$(( $wskr_fn_end - ${#line2} - ${#line3} - 2 ))
    CURSOR=$wskr_fn_begin
    cols=$(tput cols)
    wsline_maxlen=$(( $cols - ${#line1} - 1))
    wsline-init "kr-upd"
    zle -K wskr-line
    kr-upd
}

kr-upd() {
    region_highlight=$wskr_rh_save
    local start=$(( ${#BUFFER} - $wskr_fn_end ))
    ws-do-bold $start  2 8  16 25  29 31  44 47  64 67  71 73
}

kr-close() {
    local end=$(( ${#BUFFER} - $wskr_end + 1 ))
    BUFFER=$BUFFER[1,$wskr_start]$BUFFER[$end,${#BUFFER}]
    CURSOR=$wskr_curs
    unset wskr_start
    unset wskr_end
    unset wskr_curs
    unset wskr_fn_begin
    unset wskr_fn_end
    unset wskr_fn
    unset wskr_l4
    unset wskr_l4end
    region_highlight=$wskr_rh_save
    zle -K $wskr_kmsave
}

zle -N kr-restore
bindkey -M wskr-line "^U" kr-restore
kr-restore() {
    kr-close
    wskr_text=""
    $wskr_insert
}

zle -N krline-accept
bindkey -M wskr-line "^M" krline-accept
krline-accept() {
    # get file name
    local fn_end=$(( ${#BUFFER} - $wskr_fn_end ))
    wskr_fn=$BUFFER[$(( $wskr_fn_begin + 1 )),$fn_end]

    # get file contents
    wskr_text=$(cat $wskr_fn 2>&-)
    local res=$?

    # check if no error
    if [[ $res != 0 ]]; then
	kr-file-error
        zle -K wskr-eread
    else
	kr-close
        $wskr_insert
    fi
}

kr-file-error() {
    wskr_save_curs=$CURSOR
    local line4a="ZSH cannot open that document."
    local line4b="  Press Enter to continue."
    local line4=$line4a$line4b
    local i=$(( ${#region_highlight} + 1 ))
    local end=$(( ${#BUFFER} - $wskr_end ))
    wskr_l4=$end
    BUFFER[$wskr_l4]=$BUFFER[$wskr_l4]$'\n'$line4
    wskr_l4end=$(( $wskr_l4 + ${#line4} ))
    CURSOR=$(( $wskr_l4end + 1 ))
    local so_end=$(( $wskr_l4 + ${#line4a} + 1 ))
    region_highlight[$i]=("$wskr_l4 $so_end standout")
}

zle -N kr-del-l4
bindkey -M wskr-eread "^U" kr-del-l4
bindkey -M wskr-eread "^M" kr-del-l4
kr-del-l4() {
    local end=$(( ${#BUFFER} - $wskr_end + 1 ))
    BUFFER=$BUFFER[1,$wskr_l4]$BUFFER[$end,${#BUFFER}]
    unset wskr_l4
    unset wskr_l4end
    CURSOR=$wskr_save_curs
    local i=${#region_highlight}
    region_highlight[$i]=""
    unset wskr_text
    zle -K wskr-line
}
