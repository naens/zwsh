# test wsline: enter different wsline and exit to main buffer

# Concept:
# On launch: 2 fields 8 and 12 characters.
# Tab: go to other field
# Enter: 1: go to field 2, 2: exit accepting
# Esc: 1: exit cancelling, 2: go to field 1.
zle -N testinit
bindkey -M wskeys "^[p" testinit
testinit() {
    wstestline_oldbuffer="$BUFFER"
    wstestline_oldcursor=$CURSOR
    wstestline_oldtextvar=$wstext_textvar
    wstestline_oldupdfnvar=$wstext_updfnvar
    wstestline_oldposvar=$wstext_posvar
    LBUFFER+=$'\n'
    LBUFFER+="Field1: >>>"
    wsline-init "test1" $CURSOR 8 "^I" wsline-test1-tab
    LBUFFER+="<<<"
    LBUFFER+=$'\n'
    LBUFFER+="Field2: [[["
    wsline-init "test2" $CURSOR 12 "^I" wsline-test2-tab
    LBUFFER+="]]]"
    LBUFFER+=$'\n'
    wsline-activate "test1"
}

# when quitting, restore previous state
wstestline-restore() {
    BUFFER="$wstestline_oldbuffer"
    CURSOR="$wstestline_oldcursor"
    wstext_textvar=$wstestline_oldtextvar
    wstext_updfnvar=$wstestline_oldupdfnvar
    wstext_posvar=$wstestline_oldposvar
    zle -K wskeys
}

# test1 functions
wsline-test1-tab() {
    wsline-activate "test2"
}

wsline-test1-accept() {
    wsline-activate "test2"
}

# test1: quit on cancel
wsline-test1-cancel() {
    wsline-exit "test1"
    wsline-exit "test2"    # restores original mode && calls update
    wstestline-restore
    zle -M "not accepted!"
}

# test2 functions
wsline-test2-tab() {
    wsline-activate "test1"
}

# test2: quit on accept
wsline-test2-accept() {
    local field1="$(ws-printvar wsline_test1_text)"
    local field2="$(ws-printvar wsline_test2_text)"
    wsline-exit "test1"
    wsline-exit "test2"    # unsets variables
    wstestline-restore
    zle -M "accepted: field1=\"$field1\" field2=\"$field2\""
}

wsline-test2-cancel() {
    wsline-activate "test1"
}
