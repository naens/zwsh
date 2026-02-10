# Tests for wstxtfun-pos: converts position to (row, col)
# wstxtfun-pos <pos> <text> => "row col"

# single line, position at start
assert_eq "$(wstxtfun-pos 0 'abcdef')" "1 1" "pos 0 in single line"

# single line, position in middle
assert_eq "$(wstxtfun-pos 3 'abcdef')" "1 4" "pos 3 in single line"

# single line, position at end
assert_eq "$(wstxtfun-pos 6 'abcdef')" "1 7" "pos 6 in 6-char line"

# multiline, first line
assert_eq "$(wstxtfun-pos 2 $'abc\ndef')" "1 3" "pos 2 in multiline"

# multiline, second line start
assert_eq "$(wstxtfun-pos 4 $'abc\ndef')" "2 1" "pos 4 at start of line 2"

# multiline, second line middle
assert_eq "$(wstxtfun-pos 6 $'abc\ndef')" "2 3" "pos 6 in line 2"

# three lines
assert_eq "$(wstxtfun-pos 8 $'ab\ncd\nef')" "3 3" "pos 8 in line 3"

# with tab
assert_eq "$(wstxtfun-pos 2 $'a\tb')" "1 9" "pos 2 after tab"
