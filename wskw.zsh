# Inserts dialog line at the end of the next string:
#     Write to file: __________________________
#      RETURN done | Backspace or ^H erase left
#       ^U cancel  |       Del or ^G erase char
# -> file name field scrollable if text too long
# after cancel or write: delete dialog lines
# !!! if screen resize: reposition dialog
# dialog navigation:    ^S=left        ^D=right  
#                       ^QS=start-line ^QD=end-line
#                       ^A=word-left   ^F=word-right
# delete commands:      ^G=char-right  ^H=char-left
#                       ^Y=line        ^T=word-right
#                       ^QY=line-right ^Q^H,^QDEL,^Q^DEL=line-left
# accept commands: Enter, ^M => write file or fail with error message
# if file exists, display:
#     That file already exists. Overwrite (Y/N)?
# in bold: RETURN, Backspace, ^H, ^U, Del, ^G
# in standout: "That file already exists."
# kw values: kw=1: filename field active: wait for Enter (accept) or ^U (cancel)
#            kw=2: [L4] overwrite? yes/no -> enter 'y' or 'n', ^U (ret to wtf)
#            kw=3: [L4] error occured -> enter=try again, ^U (ret to wtf)
bindkey -N wskw-line wsline
bindkey -N wskw-file-exists
bindkey -N wskw-ewrite

ws-kwfn() {
    wskw_rh_save=$region_highlight
    wskw_kmsave=$KEYMAP
    wskw_curs=$CURSOR
    zle end-of-line
    wskw_start=$CURSOR
    local line1="Write to file: "
    local line2=" RETURN done | Backspace or ^H erase left"
    local line3="  ^U cancel  |       Del or ^G erase char"
    LBUFFER+=$'\n'$line1$'\n'$line2$'\n'$line3
    wskw_wtf=$(( $wskw_start + ${#line1} + 1 ))
    wskw_wtf_end=$(( ${#BUFFER} - $wskw_wtf ))
    wskw_end=$(( $wskw_wtf_end - ${#line2} - ${#line3} - 2 ))
    CURSOR=$wskw_wtf
    cols=$(tput cols)
    wsline_maxlen=$(( $cols - ${#line1} - 1))
    wsline-init "kw-upd"
    zle -K wskw-line
    kw-upd
}

kw-upd() {
    region_highlight=$wskw_rh_save
    local start=$(( ${#BUFFER} - $wskw_wtf_end ))
    ws-do-bold $start  2 8  16 25  29 31  44 47  64 67  71 73
}

# unsets kw variables, removes kw lines, restores cursor, remove highlighting
zle -N kw-close
bindkey -M wskw-line "^U" kw-close
kw-close() {
    local end=$(( ${#BUFFER} - $wskw_end + 1 ))
    BUFFER=$BUFFER[1,$wskw_start]$BUFFER[$end,${#BUFFER}]
    CURSOR=$wskw_curs
    unset wskw_start
    unset wskw_end
    unset wskw_curs
    unset wskw_wtf
    unset wskw_wtf_end
    unset wskw_fn
    unset wskw_l4
    unset wskw_l4end
    region_highlight=$wskw_rh_save
    zle -K $wskw_kmsave
    if [[ -n $kw_restore ]]; then
        $kw_restore
    fi
}

zle -N kwline-accept
bindkey -M wskw-line "^M" kwline-accept
kwline-accept() {
    # get file name
    local fn_end=$(( ${#BUFFER} - $wskw_wtf_end ))
    wskw_fn=$BUFFER[$(( $wskw_wtf + 1 )),$fn_end]

    # check if file exists
    if [[ -f $wskw_fn ]]; then
	kw-file-exists
    else
	kw-wtf
    fi
}

zle -N kw-del-l4
bindkey -M wskw-ewrite "^M" kw-del-l4

zle -N kw-wtf
bindkey -M wskw-file-exists "y" kw-wtf
bindkey -M wskw-file-exists "Y" kw-wtf
# try to write to file, if not successful, L4 warning
# returns 0 if ok, 1 if error
kw-wtf() {
    $ws_echo "$wsblock_text" 2>&- > "$wskw_fn"
    if [[ $? -eq 0 ]]; then    # remove lines 1-4, restore cursor
	kw-close
    else		      # display error message in L4
	kw-write-error
    fi
}

bindkey -M wskw-file-exists "n" kw-del-l4
bindkey -M wskw-file-exists "N" kw-del-l4
bindkey -M wskw-file-exists "^U" kw-del-l4

# replace L4, enter kw=3 mode
kw-write-error() {
    local line4a="Error writing file \"$wskw_fn\"."
    local line4b="  Press Enter to continue."
    local line4=$line4a$line4b
    local i=${#region_highlight}
    local end=$(( ${#BUFFER} - $wskw_end ))
    if [[ -n $wskw_l4 ]]; then
	BUFFER=$BUFFER[1,$wskw_l4]$'\n'$line4$BUFFER[$end, ${#BUFFER}]
    else
	i=$(( $i + 1 ))
	wskw_l4=$end
	BUFFER[$wskw_l4]=$BUFFER[$wskw_l4]$'\n'$line4
    fi
    wskw_l4end=$(( $wskw_l4 + ${#line4} ))
    CURSOR=$(( $wskw_l4end + 1 ))
    local so_end=$(( $wskw_l4 + ${#line4a} + 1 ))
    region_highlight[$i]=("P$wskw_l4 $so_end standout")
    zle -K wskw-ewrite # Enter=confirm
}

# every L4 must have exactly 1 highlight region
kw-del-l4() {
    local end=$(( ${#BUFFER} - $wskw_end + 1 ))
    BUFFER=$BUFFER[1,$wskw_l4]$BUFFER[$end,${#BUFFER}]
    unset wskw_l4
    unset wskw_l4end
    CURSOR=$wskw_wtf
    local i=${#region_highlight}
    region_highlight[$i]=""
    zle -K wskw-line
}

kw-file-exists() {
    # display question
    local line4a="That file already exists."
    local line4b="  Overwrite (Y/N)?"
    wskw_l4=$(( ${#BUFFER} - $wskw_end ))
    local line4a_end=$(( $wskw_l4 +  ${#line4a}))
    wskw_l4end=$(( $line4a_end + ${#line4b} ))
    BUFFER[$wskw_l4]=$BUFFER[$wskw_l4]$'\n'$line4a$line4b
    CURSOR=$(( $wskw_l4end + 1 ))
    # wskw_end needs not to be updated
    # wait for answer
    local i=$(( ${#region_highlight} + 1))
    region_highlight[$i]=("$wskw_l4 $line4a_end standout")
    zle -K wskw-file-exists
}
