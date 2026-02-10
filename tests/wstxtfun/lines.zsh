# Tests for wstxtfun line navigation functions

# --- wstxtfun-line-start ---
# from middle of first line
assert_eq "$(wstxtfun-line-start 3 'abcdef')" "0" "line-start on single line"

# from second line
assert_eq "$(wstxtfun-line-start 6 $'abc\ndef')" "4" "line-start on line 2"

# from third line
assert_eq "$(wstxtfun-line-start 9 $'ab\ncd\nef')" "6" "line-start on line 3"

# --- wstxtfun-line-end ---
# single line
assert_eq "$(wstxtfun-line-end 1 'abcdef')" "6" "line-end on single line"

# first line of multiline
assert_eq "$(wstxtfun-line-end 1 $'abc\ndef')" "3" "line-end on line 1 multiline"

# second line of multiline
assert_eq "$(wstxtfun-line-end 5 $'abc\ndef')" "7" "line-end on line 2"

# --- wstxtfun-line2pos ---
assert_eq "$(wstxtfun-line2pos 1 $'abc\ndef\nghi')" "1" "line2pos line 1"
assert_eq "$(wstxtfun-line2pos 2 $'abc\ndef\nghi')" "5" "line2pos line 2"
assert_eq "$(wstxtfun-line2pos 3 $'abc\ndef\nghi')" "9" "line2pos line 3"

# --- wstxtfun-nlines ---
assert_eq "$(wstxtfun-nlines 'abc')" "1" "nlines single line"
assert_eq "$(wstxtfun-nlines $'abc\ndef')" "2" "nlines two lines"
assert_eq "$(wstxtfun-nlines $'a\nb\nc')" "3" "nlines three lines"

# --- wstxtfun-pos2line ---
assert_eq "$(wstxtfun-pos2line 2 $'abc\ndef\nghi')" "1" "pos2line in line 1"
assert_eq "$(wstxtfun-pos2line 5 $'abc\ndef\nghi')" "2" "pos2line in line 2"
assert_eq "$(wstxtfun-pos2line 9 $'abc\ndef\nghi')" "3" "pos2line in line 3"

# --- wstxtfun-line-len ---
assert_eq "$(wstxtfun-line-len 1 $'abc\ndef')" "3" "line-len line 1"
assert_eq "$(wstxtfun-line-len 2 $'abc\ndef')" "3" "line-len line 2"
assert_eq "$(wstxtfun-line-len 1 $'abcde\nfg')" "5" "line-len 5 chars"

# --- wstxtfun-line-last-pos ---
assert_eq "$(wstxtfun-line-last-pos 1 $'abc\ndef')" "3" "line-last-pos line 1"
assert_eq "$(wstxtfun-line-last-pos 2 $'abc\ndef')" "7" "line-last-pos line 2"

# --- wstxtfun-yx-pos ---
assert_eq "$(wstxtfun-yx-pos 1 1 $'abc\ndef')" "0" "yx-pos row=1 col=1"
assert_eq "$(wstxtfun-yx-pos 1 3 $'abc\ndef')" "2" "yx-pos row=1 col=3"
assert_eq "$(wstxtfun-yx-pos 2 2 $'abc\ndef')" "5" "yx-pos row=2 col=2"
