bindkey -N wsedit wskeys

wsedit-pre-redraw() {
    if [[ $CURSOR -le $wsedit_begin ]]; then
        CURSOR=$wsedit_begin
    fi
    wsedit-refresh
}

# Cursor Scroll Functions TODO: ^ W/^Z (scroll line)
bindkey -M wsedit "^W" undefined-key
bindkey -M wsedit "^Z" undefined-key

# Cursor Screen Functions TODO: ^QE/^QX (begin/end screen)
bindkey -M wsedit "^Qe" undefined-key
bindkey -M wsedit "^QE" undefined-key
bindkey -M wsedit "^Qx" undefined-key
bindkey -M wsedit "^QX" undefined-key

# Insert Keys
zle -N wsedit-newline
bindkey -M wsedit "^M" wsedit-newline
wsedit-newline() {
    LBUFFER+=$'\n'
}

zle -N wsedit-splitline
bindkey -M wsedit "^N" wsedit-splitline
wsedit-splitline() {
    local curs=$CURSOR
    LBUFFER+=$'\n'
    CURSOR=$curs
}

zle -N wsedit-tab
bindkey -M wsedit "^I" wsedit-tab
wsedit-tab() {
    LBUFFER+=$'\t'
}

#zle -N wsedit-self-insert
#bindkey -M wsedit -R "!"-"~" wsedit-self-insert
#bindkey -M wsedit " " wsedit-self-insert
#wsedit-self-insert() {
#    LBUFFER+=$KEYS
#}

# Delete Keys
zle -N wsedit-delchar
bindkey -M wsedit "^G" wsedit-delchar
wsedit-delchar() {
    zle delete-char
}

zle -N wsedit-backdelchar
bindkey -M wsedit "^H" wsedit-backdelchar
bindkey -M wsedit "^?" wsedit-backdelchar
wsedit-backdelchar() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle backward-delete-char
    fi
}

zle -N wsedit-delline
bindkey -M wsedit "^Y" wsedit-delline
wsedit-delline() {
    if [[ $wsedit_begin -lt ${#BUFFER} ]]; then
        zle kill-whole-line
    fi
}

zle -N wsedit-back-delline
bindkey -M wsedit "^Q^H" wsedit-back-delline
wsedit-back-delline() {
    if [[ $CURSOR -gt $wsedit_begin ]]; then
        zle backward-kill-line
    fi
}

# Switch main to editor mode key bindings
# Switch to editor mode: ^KD
zle -N ws-edit
bindkey -M wskeys "^Kd" ws-edit
bindkey -M wskeys "^KD" ws-edit
#bindkey -M wsblock "^Kd" ws-edit
#bindkey -M wsblock "^KD" ws-edit
ws-edit() {
    wsedit_saved_keymap=$KEYMAP
    wsedit_begin=0     # no header yet

    # TODO: check if enter fullscreen mode or not
    wsedit_fullscreen=false
#    if [[ $KEYMAP == "wsblock" ]]; then
#        skip
#    else
        zle -K wsedit
#    fi

    # save previous vars
    wstext_textvar_save=$wstext_textvar
    wstext_updfnvar_save=$wstext_updfnvar
    wstext_posvar_save=$wstext_posvar

    wsedit_text="${(P)wstext_textvar}"
    wsedit_pos=${(P)wstext_posvar}

    # define variables
    wstext_textvar=wsedit_text
    wstext_updfnvar=wsedit-refresh
    wstext_posvar=wsedit_pos
}

# overwrite area between 0 and $wsedit_begin with an updated header
# update $wsedit_begin to match the next character after the header
wsedit-header() {
    local begin_old=$wsedit_begin
#    local curs_old=$CURSOR
    ws-pos $wsedit_begin
    local ostr="Insert"
    if [[ $ZLE_STATE == *overwrite* ]]; then
        ostr=""
    fi
    local fn="<FILENAME>"
    local header_text=$(printf "%16s       L%05d  C%03d %s" \
                               $fn $ws_row $ws_col $ostr)
    BUFFER[1,$wsedit_begin]=$'\n'$header_text$'\n'
    # wsedit_ begin of editable area
    wsedit_begin=$(( ${#header_text} + 2 ))

#    local diff=$(( $wsedit_begin - $begin_old ))
    #CURSOR=$(( $curs_old + $diff ))
#    if [[ -n $kb ]]; then
#        kb=$(( $kb + $diff ))
#    fi
#    if [[ -n $kk ]]; then
#        kk=$(( $kk + $diff ))
#    fi
}

# refresh all: the text and the header
wsedit-refresh() {
    # TODO: update $ws_text and other text varisables
    if $wsedit_fullscreen; then
        ws-size       # define $ws_rows and $ws_cols
        wsedit-header # displays header on the first row
        
        # TODO: update text display...
    else
        wsedit-header
    fi
    ws-debug WSEDIT_REFRESH wsedit_text=\""$wsedit_text"\" wsedit_pos=$wsedit_pos
    BUFFER[wsedit_begin+1,${#BUFFER}]="$wsedit_text"
    CURSOR=$((wsedit_begin+wsedit_pos))
}

# Switch to *editor mode* and open a file: ^KE
# Switch to *editor mode* saving buffer as file: ^KS

# Switch /editor mode/ to main mode
# Exit *editor mode* (do not save), with file contents as buffer: ^KD
# TODO: in fullscreen mode, text can have more lines than the buffer
#       if text bigger, than the buffer, put the whole text in the buffer
#       if text smaller, remove supplementary lines from the buffer
#         => !!! cursor position
zle -N wsedit-exit
bindkey -M wsedit "^Kd" wsedit-exit
bindkey -M wsedit "^KD" wsedit-exit
wsedit-exit() {
    CURSOR=$(( $CURSOR - $wsedit_begin ))
#    if [[ $KEYMAP == "wseditblock" ]]; then
#        kb=$(( $kb - $wsedit_begin ))
#        if [[ -n $kk ]]; then
#            kk=$(( $kk - $wsedit_begin ))
#        fi
#        zle -K wsblock
#        wsblock-upd
#    else
#        zle -K $wsedit_saved_keymap
#    fi
#    BUFFER[1,$wsedit_begin]=""

    # define variables
    wstext_textvar=$wstext_textvar_save
    wstext_updfnvar=$wstext_updfnvar_save
    wstext_posvar=$wstext_posvar_save

    eval "$wstext_textvar=\"$wsedit_text\""
    eval "$wstext_posvar=\"$wsedit_pos\""
    ws-debug "$wstext_textvar -> $wsedit_text"
    ws-debug "$wstext_posvar -> $wsedit_pos"

    unset wsedit_begin
    unset wsedit_text
    unset wsedit_pos
    zle -K $wsedit_saved_keymap
    $wstext_updfnvar
}

# Close the currenpt file and save: ^KX (buffer empty)
# Close the current file without saving: ^KQ (buffer empty)

# Enter fullscreen mode
zle -N wsedit-fullscreen
bindkey -M wsedit "^Kf" wsedit-fullscreen
bindkey -M wsedit "^KF" wsedit-fullscreen
wsedit-fullscreen() {
    # toggle fullscreen mode
    wsedit_fullscreen=$(not $wsedit_fullscreen)

}


# Block functions
#zle -N wseditblock-kb
#bindkey -M wsedit "^Kb" wseditblock-kb
#bindkey -M wsedit "^KB" wseditblock-kb

# TODO: * file import/export functions
# TODO: * dialog=new screen!!! => save-and-replace buffer
zle -N wsedit-kr
bindkey -M wsedit "^Kr" wsedit-kr
bindkey -M wsedit "^KR" wsedit-kr
wsedit-kr() {
    wsedit_savebuf=$BUFFER[$(( $wsedit_begin + 1 )),${#BUFFER}]
    wsedit_savecurs=$(( $CURSOR - $wsedit_begin ))
    BUFFER=""
    ws-krfn
    wskr_insert="wsedit-kr-insert"
}

wsedit-kr-insert() {
    wsedit_begin=0
    BUFFER=$wsedit_savebuf
    CURSOR=$wsedit_savecurs
    LBUFFER+=$wskr_text
    unset wskr_text
}

# TODO: * file functions: ^KE=open, ^KS=save, ^KO=copy
bindkey -M wsedit "^Ke" undefined-key
bindkey -M wsedit "^KE" undefined-key
bindkey -M wsedit "^Ks" undefined-key
bindkey -M wsedit "^KS" undefined-key
bindkey -M wsedit "^Ko" undefined-key
bindkey -M wsedit "^KO" undefined-key

# TODO: * exit+close functions: ^KX=saving ^KQ=not-saving
bindkey -M wsedit "^Kx" undefined-key
bindkey -M wsedit "^KX" undefined-key
bindkey -M wsedit "^Kq" undefined-key
bindkey -M wsedit "^KQ" undefined-key

# TODO: * enter+open functions: ^KE=replace ^KS=keep-and-save
bindkey -M wskeys "^Ke" undefined-key
bindkey -M wskeys "^KE" undefined-key
bindkey -M wskeys "^Ks" undefined-key
bindkey -M wskeys "^KS" undefined-key

# TODO: * Find functions
bindkey -M wsedit "^Qf" undefined-key
bindkey -M wsedit "^QF" undefined-key
bindkey -M wsedit "^L" undefined-key
