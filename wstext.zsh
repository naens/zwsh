# Word functions: find space->word boundaries (first character of the word)
wstext-next-word() {
    local pos=$1
    local text="$2"
    local max=${#text}

    # skip word or end of text
    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done

    # skip until next word
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_pos=$((i-1))
}

wstext-prev-word() {
    local pos=$1
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

wstext-end-word() {
    local pos=$1
    local text="$2"
    local max=${#text}

    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_pos=$((i-1))
}

wstext-next-printable() {
    local pos=$1
    local text="$2"
    local max=${#text}

    local i=$((pos+1))
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_pos=$((i-1))
}


# Line functions
wstext-line-start() {}
wstext-line-len() {}
wstext-pos2line() {}

# Sentence functions
wstext-next-sentence() {}
wstext-prev-sentence() {}

wstext-upd() {
    if typeset -f $wstext_updfnvar > /dev/null; then
        $wstext_updfnvar
    fi
}

# Paragraph functions
wstext-next-paragraph() {}
wstext-prev-paragraph() {}

# Delete character functions
wstext-del-char-left() {
    local pos="$1"
    if [[ $pos -eq 0 ]]; then
        wstext_pos=$pos
    else
        local textvar="$2"
        local text="${(P)textvar}"
        local end=${#text}
        eval $textvar=\'$text[1,pos-1]$text[pos+1,end]\'
        wstext_pos=$((pos-1))
        wstext-upd
    fi
}

wstext-del-char-right() {
    local pos="$1"
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}
    if [[ $pos -lt $end ]]; then
        eval $textvar=\'$text[1,pos]$text[pos+2,end]\'
    fi
    wstext_pos=$((pos))
    wstext-upd
}

# Delete word functions
wstext-del-word-left() {
    local pos="$1"
    local textvar="$2"
    local text="${(P)textvar}"
    wstext-prev-word $pos "$text"
    local from=$wstext_pos
    local end=${#text}
    eval $textvar=\'$text[1,from]$text[pos+1,end]\'
    wstext_pos=$from
    wstext-upd
}

# what it does: at word start: delete word, delete all non-printable characters that follow
#               word middle: delete until end of word (do not touch any printable or non-printable characters that follow)
#               non-word printable: delete 1 char + delete non-printable that follow
#               non-word non-printable: delete all non-printable that follow cursor position
wstext-del-word-right() {
    local pos="$1"
    local textvar="$2"
    local text="${(P)textvar}"
    wstext-prev-word $((pos+1)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos
    wstext-next-word $pos "$text"
    local to=$wstext_pos
    local end=${#text}
    echo pos=$pos word_begin=$word_begin > $debugfile
    if [[ $pos -eq $word_begin ]]; then
        wstext-next-printable $word_end "$text"
        local del_end=$wstext_pos
        eval $textvar=\'$text[1,pos]$text[del_end+1,end]\'
    elif [[ $pos -lt $word_end ]]; then
        eval $textvar=\'$text[1,pos]$text[word_end+1,end]\'
    else
        wstext-next-printable $((pos+1)) "$text"
        local next_printable=$wstext_pos
        eval $textvar=\'$text[1,pos]$text[next_printable+1,end]\'
    fi
    wstext_pos=$pos
    wstext-upd
}

# delete whole word if inside a word, otherwise works like del-word-right
wstext-del-word() {
    local pos="$1"
    local textvar="$2"
    local text="${(P)textvar}"
    
    wstext-prev-word $((pos+1)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos

    if [[ $pos -ge $word_begin && $pos -lt $word_end ]]; then
        wstext-del-word-right $word_begin "$textvar"
    else
        wstext-del-word-right $pos "$textvar"
    fi    
}

# Delete line functions
wstext-del-line-left() {}
wstext-del-line-right() {}
wstext-del-line() {}

# Delete sentence functions
wstext-del-sentence-left() {}
wstext-del-sentence-right() {}
wstext-del-sentence() {}

# Delete paragraph functions
wstext-del-paragraph-left() {}
wstext-del-paragraph-right() {}
wstext-del-paragraph() {}

# Insert functions: insert text after position
wstext-insert() {
    local pos="$1"
    local str="$2"
    local textvar="$3"
    local text="${(P)textvar}"
    local sz=${#text}
    if [[ $pos -eq 0 ]]; then
        eval $textvar=\'$str$text\'
    else
        eval $textvar=\'$text[1,pos]$str$text[pos+1,sz]\'
    fi
    wstext_pos=$((pos + ${#str}))
    wstext-upd
}
