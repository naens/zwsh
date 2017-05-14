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

wstext-prev-printable() {
    local pos=$1
    local text="$2"
    local max=${#text}

    local i=$pos
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    wstext_pos=$i
}

# Line functions
wstext-line-start() {
    local pos=$1
    local text="$2"
    
    local i=$pos
    while [[ ! "$text[i]" = $'\n' && $i -ge 1 ]]; do
        i=$((i-1))
    done
    wstext_pos=$i
}

wstext-line-end() {
    local pos=$1
    local text="$2"
    local max=${#text}
    
    local i=$((pos+1))
    while [[ ! "$text[i]" = $'\n' && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_pos=$((i-1))
}

wstext-line2pos() {
    local line=$1
    local text="$2"
    local i=1
    local curr=1
    local max=${#text}

    while [[ $curr -lt $line && $i -le $max ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
    wstext_pos=$i
}

wstext-line-len() {
    local line=$1
    local text="$2"
    local max=${#text}

    wstext-line2pos $line "$text"

    local begin=$wstext_pos
    local i=$wstext_pos
    while [[ ! "$text[i]" = $'\n' && $i -le $max ]]; do
        i=$((i+1))
    done
    wstext_linelen=$((i-begin))
}

wstext-pos2line() {
    local pos=$1
    local text="$2"
    local i=1
    local curr=1
    local max=${#text}

    while [[ $i -lt $pos && $i -le $max ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
    wstext_line=$curr
}


# Sentence functions (end-of-sentence: dot-space-space or dot-newline)
wstext-next-sentence() {
    local pos=$1
    local text="$2"
    local max=${#text}

    #find next printable character
    local i=$((pos+1))
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $max ]]; do
        i=$((i+1))
    done

    # find next sentence end
    
    wstext_pos=$((i-1))
}

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
        ws-defvar $textvar "$text[1,pos-1]$text[pos+1,end]"
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
        ws-defvar $textvar "$text[1,pos]$text[pos+2,end]"
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
    ws-defvar $textvar "$text[1,from]$text[pos+1,end]"
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
    wstext-prev-word $((pos+2)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos
    wstext-next-word $pos "$text"
    local next_word=$wstext_pos
    local end=${#text}
    ws-debug pos=$pos word_begin=$word_begin
    if [[ $pos -le $word_begin ]]; then
        wstext-next-printable $word_end "$text"
        local del_end=$wstext_pos
        if [[ $pos -eq 0 && $de_end -eq 0 ]]; then
            ws-defvar $textvar "$text[2,end]"
        else
            ws-defvar $textvar "$text[1,pos]$text[del_end+1,end]"
        fi
    elif [[ $pos -lt $word_end ]]; then
        ws-defvar $textvar "$text[1,pos]$text[word_end+1,end]"
    else
        wstext-next-printable $((pos+1)) "$text"
        local next_printable=$wstext_pos
        if [[ $next_printable -eq $next_word ]]; then
            ws-defvar $textvar "$text[1,pos]$text[next_printable,end]"
        else
            ws-defvar $textvar "$text[1,pos]$text[next_printable+1,end]"
        fi
    fi
    wstext_pos=$pos
    wstext-upd
}

# delete whole word if inside a word and characters and non-printable outside
wstext-del-word() {
    local pos="$1"
    local textvar="$2"
    local text="${(P)textvar}"
    wstext-prev-word $((pos+2)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos
    wstext-next-word $pos "$text"
    local to=$wstext_pos
    local end=${#text}
    if [[ $pos -lt $word_end ]]; then
        wstext-next-printable $word_end "$text"
        local del_end=$wstext_pos
        local from=$(ws-min $word_begin $pos)
        ws-defvar $textvar "$text[1,from]$text[del_end+1,end]"
        wstext_pos=$from
    else
        wstext-prev-printable $pos "$text"
        local prev_printable=$wstext_pos
        wstext-next-printable $((pos+1)) "$text"
        local next_printable=$wstext_pos
        ws-defvar $textvar "$text[1,prev_printable]$text[next_printable+1,end]"
        wstext_pos=$prev_printable
    fi
    wstext-upd
}

# Delete line functions
wstext-del-line-left() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}
    wstext-line-start $pos "$text"
    local from=$wstext_pos
    ws-defvar $textvar "$text[1,from]$text[pos+1,end]"
    wstext_pos=$from
    wstext-upd
}

wstext-del-line-right() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}
    wstext-line-start $pos "$text"
    local begin=$wstext_pos
    wstext-line-end $pos "$text"
    local to=$wstext_pos
    if [[ $begin -eq $pos && $to -lt $end ]]; then
        ws-defvar $textvar "$text[1,pos]$text[to+2,end]"
    else
        ws-defvar $textvar "$text[1,pos]$text[to+1,end]"
    fi
    wstext_pos=$pos
    wstext-upd    
}

wstext-del-line() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}
    wstext-line-start $pos "$text"
    local from=$wstext_pos
    wstext-line-end $pos "$text"
    local to=$wstext_pos
    if [[ $to -lt $end ]]; then
        ws-defvar $textvar "$text[1,from]$text[to+2,end]"
    else
        ws-defvar $textvar "$text[1,from]$text[to+1,end]"
    fi
    wstext_pos=$from
    wstext-upd    
}

# Delete sentence functions
wstext-del-sentence-left() {}
wstext-del-sentence-right() {}
wstext-del-sentence() {}

# Delete paragraph functions
wstext-del-paragraph-left() {}
wstext-del-paragraph-right() {}
wstext-del-paragraph() {}

# Insert functions: insert text after position: !! substitute single quote by "'"...
wstext-insert() {
    local pos=$1
    local str="$2"
    local textvar="$3"
    local text="${(P)textvar}"
    local sz=${#text}
    if [[ $pos -eq 0 ]]; then
        ws-defvar $textvar "$str$text"
    else
        ws-defvar $textvar "$text[1,pos]$str$text[pos+1,${#text}]"
    fi
    wstext_pos=$((pos + ${#str}))
    wstext-upd
}
