# Tests for wstext module: insert, delete, cursor movement
# wstext operates on named variables via indirect references

# --- Setup ---
wstext_textvar=test_text
wstext_updfnvar=test_updfn
wstext_posvar=test_pos
wstext_marksvar=test_marks
wstext_blockvisvar=test_blockvis
unset wstext_blockcolmodevar

test_updfn() { : }   # no-op update function
typeset -A test_marks

# Helper: reset state
test_reset() {
    test_text="$1"
    test_pos=${2:-0}
    test_marks=()
    unset test_blockvis
}

# --- wstext-insert ---
test_reset "hello"
test_pos=5
wstext-insert " world"
assert_eq "$test_text" "hello world" "insert at end"
assert_eq "$test_pos" "11" "cursor after insert at end"

test_reset "hello"
test_pos=0
wstext-insert "say "
assert_eq "$test_text" "say hello" "insert at start"
assert_eq "$test_pos" "4" "cursor after insert at start"

test_reset "hllo"
test_pos=1
wstext-insert "e"
assert_eq "$test_text" "hello" "insert in middle"
assert_eq "$test_pos" "2" "cursor after insert in middle"

# --- wstext-delete ---
test_reset "hello"
wstext-delete 1 1
assert_eq "$test_text" "ello" "delete first char"

test_reset "hello"
wstext-delete 5 5
assert_eq "$test_text" "hell" "delete last char"

test_reset "hello"
wstext-delete 2 4
assert_eq "$test_text" "ho" "delete middle range"

# --- wstext-char-left ---
test_reset "hello" 3
wstext-char-left
assert_eq "$test_pos" "2" "char-left from middle"

test_reset "hello" 0
wstext-char-left
assert_eq "$test_pos" "0" "char-left at start stays"

# --- wstext-char-right ---
test_reset "hello" 3
wstext-char-right
assert_eq "$test_pos" "4" "char-right from middle"

test_reset "hello" 5
wstext-char-right
assert_eq "$test_pos" "5" "char-right at end stays"

# --- wstext-start-document / wstext-end-document ---
test_reset "hello world" 5
wstext-start-document
assert_eq "$test_pos" "0" "start-document"

test_reset "hello world" 0
wstext-end-document
assert_eq "$test_pos" "11" "end-document"

# --- wstext-line-start / wstext-line-end ---
test_reset $'abc\ndef' 6
wstext-line-start
assert_eq "$test_pos" "4" "line-start on line 2"

test_reset $'abc\ndef' 5
wstext-line-end
assert_eq "$test_pos" "7" "line-end on line 2"

# --- wstext-del-char-left ---
test_reset "hello" 3
wstext-del-char-left
assert_eq "$test_text" "helo" "del-char-left"
assert_eq "$test_pos" "2" "cursor after del-char-left"

test_reset "hello" 0
wstext-del-char-left
assert_eq "$test_text" "hello" "del-char-left at start no-op"
assert_eq "$test_pos" "0" "cursor stays at 0"

# --- wstext-del-char-right ---
test_reset "hello" 2
wstext-del-char-right
assert_eq "$test_text" "helo" "del-char-right"
assert_eq "$test_pos" "2" "cursor after del-char-right"

# --- wstext-del-line ---
test_reset $'abc\ndef\nghi' 5
wstext-del-line
assert_eq "$test_text" $'abc\nghi' "del-line removes line 2"

# --- wstext-prev-word / wstext-next-word ---
test_reset "hello world" 8
wstext-prev-word
assert_eq "$test_pos" "6" "prev-word"

test_reset "hello world done" 0
wstext-next-word
assert_eq "$test_pos" "6" "next-word"

# --- Cleanup ---
unset test_text test_pos test_marks test_blockvis
