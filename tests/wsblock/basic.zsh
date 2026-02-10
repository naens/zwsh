# Tests for wsblock module: mark, copy, move, delete
# Uses the same indirect variable convention as wstext

# --- Setup ---
wstext_textvar=test_text
wstext_updfnvar=test_updfn
wstext_posvar=test_pos
wstext_marksvar=test_marks
wstext_blockvisvar=test_blockvis
unset wstext_blockcolmodevar

test_updfn() { : }
typeset -A test_marks

test_reset() {
    test_text="$1"
    test_pos=${2:-0}
    test_marks=()
    unset test_blockvis
}

# --- wsblock-undef ---
test_reset "hello" 2
test_marks[B]=1
test_marks[K]=4
test_blockvis=true
wsblock-undef
assert_eq "${test_marks[B]}" "" "undef clears B"
assert_eq "${test_marks[K]}" "" "undef clears K"
assert_eq "$test_blockvis" "" "undef clears vis"

# --- ws-kb: mark begin ---
test_reset "hello world" 3
ws-kb
assert_eq "${test_marks[B]}" "3" "kb sets B at cursor"
assert_eq "$test_blockvis" "true" "kb sets blockvis"

# toggle off
ws-kb
assert_eq "${test_marks[B]}" "" "kb at same pos unsets B"

# --- ws-kk: mark end ---
test_reset "hello world" 7
test_marks[B]=2
test_blockvis=true
ws-kk
assert_eq "${test_marks[K]}" "7" "kk sets K at cursor"

# --- wsblock-kc: copy block ---
test_reset "hello world" 0
test_marks[B]=6
test_marks[K]=11
test_blockvis=true
wsblock-kc
assert_eq "$test_text" "worldhello world" "copy block inserts at cursor"
# cursor stays at original pos: 0
assert_eq "$test_pos" "0" "cursor stays after copy"

# --- wsblock-kc: paste when no block ---
test_reset "hello" 5
unset test_blockvis
ws_delbuf=" world"
wsblock-kc
assert_eq "$test_text" "hello world" "kc pastes delbuf when no block"
unset ws_delbuf

# --- wsblock-kv: paste when no block ---
test_reset "abc" 3
unset test_blockvis
ws_delbuf="def"
wsblock-kv
assert_eq "$test_text" "abcdef" "kv pastes delbuf when no block"
unset ws_delbuf

# --- wsblock-ky: delete block ---
test_reset "hello world" 0
test_marks[B]=5
test_marks[K]=11
test_blockvis=true
wsblock-ky
assert_eq "$test_text" "hello" "ky deletes block"

# --- wsblock-kh: toggle visibility ---
test_reset "hello" 0
test_marks[B]=1
test_marks[K]=4
test_blockvis=true
wsblock-kh
assert_eq "$test_blockvis" "" "kh hides block"
wsblock-kh
assert_eq "$test_blockvis" "true" "kh shows block again"

# --- wsblock-qb / wsblock-qk: jump to marks ---
test_reset "hello world" 0
test_marks[B]=2
test_marks[K]=8
test_blockvis=true
wsblock-qb
assert_eq "$test_pos" "2" "qb jumps to B"
wsblock-qk
assert_eq "$test_pos" "8" "qk jumps to K"

# --- Cleanup ---
unset test_text test_pos test_marks test_blockvis
