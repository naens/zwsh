bindkey -N wsedit wskeys

wsedit-pre-redraw() {
    if [[ $CURSOR -le $wsedit_begin ]]; then
        CURSOR=$wsedit_begin
    fi
    wsedit-refresh
}

# Cursor Movement Functions
zle -N wsedit-prev-line
bindkey -M wsedit "^E" wsedit-prev-line
wsedit-prev-line() {
    wstext-prev-line
}

zle -N wsedit-next-line
bindkey -M wsedit "^X" wsedit-next-line
wsedit-next-line() {
    wstext-next-line
}

bindkey -M wsedit "^R" undefined-key #TODO
bindkey -M wsedit "^C" undefined-key #TODO

zle -N wsedit-start-document
bindkey -M wsedit "^Qr" wsedit-start-document
bindkey -M wsedit "^QR" wsedit-start-document
wsedit-start-document() {
    wstext-start-document
}

zle -N wsedit-end-document
bindkey -M wsedit "^Qc" wsedit-end-document
bindkey -M wsedit "^QC" wsedit-end-document
wsedit-end-document() {
    wstext-end-document
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
    wstext-insert $'\n'
}

zle -N wsedit-splitline
bindkey -M wsedit "^N" wsedit-splitline
wsedit-splitline() {
    wstext-insert $'\n'
    wsedit_pos=$((wsedit_pos-1))
    wsedit-refresh
}

zle -N wsedit-tab
bindkey -M wsedit "^I" wsedit-tab
wsedit-tab() {
    wstext-insert $'\t'
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
    local ws_row
    local ws_col
    read ws_row ws_col <<< $(wstxtfun-pos $wsedit_pos "$wsedit_text")
    local ostr="Insert"
    if [[ $ZLE_STATE == *overwrite* ]]; then
        ostr=""
    fi
    local fn="<FILENAME>"
    if [[ -n "$wsedit_fn" ]]; then
        fn="$wsedit_fn"
    fi
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
#    ws-debug WSEDIT_REFRESH wsedit_text=\""$wsedit_text"\" wsedit_pos=$wsedit_pos
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
    CURSOR=$((CURSOR-wsedit_begin))
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
    BUFFER=""
    wsdfopen_endfn=wsedit-kr-end
    wsdfopen-run
}

wsedit-kr-end() {
    wsedit_begin=0
    if [[ -n "$wsdfopen_text" ]]; then
        wstext-insert "$wsdfopen_text"
    fi
}

# open file
zle -N wsedit-open
bindkey -M wsedit "^Ke" wsedit-open
bindkey -M wsedit "^KE" wsedit-open
wsedit-open() {
    BUFFER=""
    wsdfopen_endfn=wsedit-replace-end
    wsdfopen-run
}

wsedit-replace-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfopen_fn"
        wsedit_text="$wsdfopen_text"
    fi
}

# save file
zle -N wsedit-save
bindkey -M wsedit "^Ks" wsedit-save
bindkey -M wsedit "^KS" wsedit-save
wsedit-save() {
    if [[ -n "$wsedit_fn" ]]; then
        if $ws_echo "$wsedit_text" 2>&- > "$wsedit_fn"; then
            return
        fi
    fi
    BUFFER=""
    wsdfsave_text="$wsedit_text"
    wsdfsave-run
}

# save and close 
zle -N wsedit-save-exit
bindkey -M wsedit "^Kx" wsedit-save-exit
bindkey -M wsedit "^KX" wsedit-save-exit
wsedit-save-exit() {
    if [[ -n "$wsedit_fn" ]]; then
        if $ws_echo "$wsedit_text" 2>&- > "$wsedit_fn"; then
            wsedit-save-exit-end
            return
        fi
    fi
    BUFFER=""
    wsdfsave_text="$wsedit_text"
    wsdfsave_endfn=wsedit-save-exit-end
    wsdfsave-run
}

wsedit-save-exit-end() {
    wsedit_text=""
    wsedit-exit
}

# exit without saving.  TODO: ask if need saving
zle -N wsedit-quit
bindkey -M wsedit "^Kq" wsedit-quit
bindkey -M wsedit "^KQ" wsedit-quit
wsedit-quit() {
    wsedit_text=""
    wsedit-exit
}

# replace buffer with contents from file and enter edit mode
zle -N wskeys-replace
bindkey -M wskeys "^Ke" wskeys-replace
bindkey -M wskeys "^KE" wskeys-replace
wskeys-replace() {
    wsdialog-wsdfopen-run
    wsdfopen_endfn=wstext-replace-enter
}

wstext-replace-enter() {
    if [[ "$1" = "OK" ]]; then
        ws_text="$wsdfopen_text"
        wsedit_fn="$wsdfopen_fn"
        ws-edit
    fi
}

# save buffer contents and enter edit mode
zle -N wskeys-save-edit
bindkey -M wskeys "^Ks" wskeys-save-edit
bindkey -M wskeys "^KS" wskeys-save-edit
wskeys-save-edit() {
    wsdfsave_text="$ws_text"
    wsdfsave_endfn=wskeys-save-edit-end
    wsdfsave-run
}

wskeys-save-edit-end() {
    if [[ "$1" = "OK" ]]; then
        ws-edit
    fi
}

# TODO: * Find functions
bindkey -M wsedit "^Qf" undefined-key
bindkey -M wsedit "^QF" undefined-key
bindkey -M wsedit "^L" undefined-key
