# Tests for wstxtfun word navigation functions

# --- wstxtfun-prev-word ---
# prev-word from middle of word
assert_eq "$(wstxtfun-prev-word 5 'hello world')" "0" "prev-word from middle of first word"

# prev-word from space between words
assert_eq "$(wstxtfun-prev-word 6 'hello world')" "0" "prev-word from space"

# prev-word from second word
assert_eq "$(wstxtfun-prev-word 9 'hello world')" "6" "prev-word from second word"

# prev-word from start
assert_eq "$(wstxtfun-prev-word 1 'hello world')" "0" "prev-word from start"

# --- wstxtfun-next-word ---
# next-word from start
assert_eq "$(wstxtfun-next-word 0 'hello world')" "6" "next-word from pos 0"

# next-word from middle of first word
assert_eq "$(wstxtfun-next-word 3 'hello world')" "6" "next-word from middle"

# next-word from second word
assert_eq "$(wstxtfun-next-word 7 'hello world done')" "12" "next-word to third word"

# next-word at end
assert_eq "$(wstxtfun-next-word 10 'hello world')" "11" "next-word at end"

# --- wstxtfun-end-word ---
# end-word from start of word
assert_eq "$(wstxtfun-end-word 1 'hello world')" "5" "end-word from start of hello"

# end-word from middle
assert_eq "$(wstxtfun-end-word 3 'hello world')" "5" "end-word from middle of hello"
