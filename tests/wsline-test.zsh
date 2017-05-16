# test wsline: enter different wsline and exit to main buffer

# Concept:
# On launch: 2 fields 8 and 12 characters.
# Tab: go to other field
# Enter: 1: go to field 2, 2: exit accepting
# Esc: 1: exit cancelling, 2: go to field 1.

testinit() {
    LBUFFER+=$'\n'
    LBUFFER+="Field1: >>>"
    wsline-init "test1" $CURSOR 8 "^I" wsline-test1-tab
    LBUFFER+="<<<"
    LBUFFER+=$'\n'
    LBUFFER+="Field2: >>>"
    wsline-init "test2" $CURSOR 12 "^I" wsline-test2-tab
    LBUFFER+="<<<"
    LBUFFER+=$'\n'
    wsline-activate "test1"
}

# test1 functions
wsline-test1-tab() {
    wsline-activate "test1"
}

wsline-test1-accept() {
    wsline-activate "test1"
}

wsline-test1-cancel() {
    wsline-end "test1"
    wsline-end "test2"    # restores original mode && calls update
    zle -M "not accepted!"
}

# test2 functions
wsline-test2-tab() {
    wsline-activate "test2"
}

wsline-test2-accept() {
    local field1
    local field2
    wsline-end "test1"
    wsline-end "test2"    # restores original mode && calls update
    zle -M "accepted: field1=\"$field1\" field2=\"$field2\""
}

wsline-test2-cancel() {
    wsline-activate "test2"
}
