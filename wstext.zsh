# Word functions: find space->word boundaries (first character of the word)
wstext-next-word() {
    local pos="$1"
    local text="$2"
    local max=${#text}

    # skip word or end of text
    local i=$pos
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done

    # skip until next word
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_pos=$i
}

wstext-prev-word() {
    local pos="$1"
    local text="$2"

    # skip until next word
    local i=$pos
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done

    # skip word or end of text
    while [[ "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    wstext_pos=$i
}

# Line functions
wstext-line-start() {}
wstext-line-len() {}
wstext-pos2line() {}

# Sentence functions
wstext-next-sentence() {}
wstext-prev-sentence() {}

# Delete character functions
wstext-del-char-left() {}
wstext-del-char-right() {}

# Delete word functions
wstext-del-word-left() {}
wstext-del-word-right() {}
wstext-del-word() {}

# Delete line functions
wstext-del-line-left() {}
wstext-del-line-right() {}
wstext-del-line() {}

# Delete sentence functions
wstext-del-sentence-left() {}
wstext-del-sentence-right() {}
wstext-del-sentence() {}

# Insert functions: insert text after position
wstext-insert() {
    local pos="$1"
    local str="$2"
    local textvar="$3"
    local text="${(P)textvar}"
    local sz=${#text}
    if [[ $pos -eq 0 ]]; then
        $textvar=$str$text
    else
        $textvar=$text[1,pos]$str$text[pos+1,sz]
    fi
    wstext_pos=$((pos + sz))
}