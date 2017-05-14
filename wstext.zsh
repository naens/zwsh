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

    # find next alphanumeric character
    pcre_compile -m -x "[[:alnum:]]"
    if pcre_match -b -n $pos -- $text; then
        local b=($=ZPCRE_OP)
        local pos2=$b[1]
    else
        wstext_pos=${#text}
        return
    fi

    # find sentence end
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n)"
    if pcre_match -b -n $pos2 -- $text; then
        local b2=($=ZPCRE_OP)
        wstext_pos=$b2[1]
    else
        wstext_pos=${#text}
    fi
}

wstext-prev-sentence() {
    local pos=$1
    local text="$2"

    wstext-prev-word $pos "$text"
    local x=$wstext_pos
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n|\Z)[[:punct:][:space:]]*"
    local lastb2=-1
    if pcre_match -b -- $text; then
        while [[ $? -eq 0 ]] do
            local b=($=ZPCRE_OP)
            if [[ $b[1] -gt $x ]]; then
                wstext_pos=$lastb2
                break;
            fi
            lastb2=$b[2]
            pcre_match -b -n $b[2] -- $text
        done
        if [[ ! $lastb2 -eq -1 ]]; then
            wstext_pos=$lastb2
        else
            wstext_pos=0
        fi
    else
        wstext_pos=0
    fi
}

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
        if [[ $pos -eq 0 && $del_end -eq 0 ]]; then
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

# get sentence begin / end from the position
wstext-sentence-pos() {
    local pos=$1
    local text="$2"
    local end=${#text}

    local i=1
    while [[ ! "$text[i]" =~ "[[:alnum:]]" && $i -le $end ]]; do
        i=$((i+1))
    done
    
    if [[ $pos -lt $((i-1)) || $i -gt $end ]]; then
        echo -1
        return
    fi
    local from=$i
    local to=-1
    local esen=-1
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n|\Z)[[:punct:][:space:]]*"
    if pcre_match -b -n $from -- $text; then
        while [[ $? -eq 0 ]] do
            local b=($=ZPCRE_OP)
            if [[ $b[2] -gt $pos || ($b[2] -eq $pos && $pos -eq $end)]]; then
                to=$(($b[2]+1))
                esen=$(($b[1]+1))
                break;
            fi
            from=$(($b[2]+1))
            pcre_match -b -n $b[2] -- $text
        done
        if [[ $to -eq -1 ]]; then
            echo -1
        else
            echo $from $esen $to
        fi
    else
        echo -1
    fi
}

wstext-del-sentence-left() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}

    # getting the positions of the current sentence
    local sp=($(wstext-sentence-pos $CURSOR $text))

    # return if outside of any sentence
    if [[ $sp[1] -eq -1 ]]; then
        unset wstext_pos
        return
    fi

    # if at the beginning, delete previous sentence
    if [[ $((pos+1)) -eq $sp[1] && $pos -gt 0 ]]; then
        ws-debug DEL_SENTENCE_LEFT: Delete Previous Sentence
        wstext-prev-sentence $pos "$text"
        local from=$wstext_pos
        ws-debug text=\"$text\" from=$from pos=$pos end=$end
        ws-defvar $textvar "$text[1,from]$text[pos+1,end]"
        wstext_pos=$from
        wstext-upd
    else
        # if in the middle, delete the beginning of the sentence
        ws-defvar $textvar "$text[1,$sp[1]-1]$text[pos+1,end]"
        wstext_pos=$(($sp[1]-1))
        wstext-upd
    fi
}

# deletes from the current position till the stops
wstext-del-sentence-right() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}

    local sp=($(wstext-sentence-pos $CURSOR $text))

    if [[ ! $sp[1] -eq -1 ]]; then
        ws-defvar $textvar "$text[1,$pos]$text[$sp[2],end]"
        wstext_pos=$pos
        wstext-upd
    else
        unset wstext_pos
    fi
}

wstext-del-sentence() {
    local pos=$1
    local textvar="$2"
    local text="${(P)textvar}"
    local end=${#text}

    local sp=($(wstext-sentence-pos $CURSOR $text))

    if [[ ! $sp[1] -eq -1 ]]; then
        ws-defvar $textvar "$text[1,$sp[1]-1]$text[$sp[3],end]"
        wstext_pos=$(($sp[1]-1))
        wstext-upd
    else
        unset wstext_pos
    fi
}

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
