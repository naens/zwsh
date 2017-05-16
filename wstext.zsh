# Character move functions
wstext-char-left() {
    local pos=${(P)wstext_posvar}
    local newpos=$(ws-max 0 $((pos-1)))
    eval "$wstext_posvar=$newpos"
    wstext-upd
}

wstext-char-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    local newpos=$(ws-min $text_end $((pos+1)))
    eval "$wstext_posvar=$newpos"
    wstext-upd
}

# Word functions: find space->word boundaries (first character of the word)
wstext-next-word() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    # skip word or end of text
    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done

    # skip until next word
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    eval "$wstext_posvar=$((i-1))"
    wstext-upd
}

wstext-prev-word() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"

    # skip until next word
    local i=$pos
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done

    # skip word or end of text
    while [[ "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    eval "$wstext_posvar=$i"
    wstext-upd
}

wstext-end-word() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    eval "$wstext_posvar=$((i-1))"
    wstext-upd
}

wstext-next-printable() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local i=$((pos+1))
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    eval "$wstext_posvar=$((i-1))"
}

wstext-prev-printable() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local i=$pos
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    eval "$wstext_posvar=$i"
}

# Line functions
wstext-line-start() {
    local pos=${(P)wstext_posvar}
    local text="$2"
    
    local i=$pos
    while [[ ! "$text[i]" = $'\n' && $i -ge 1 ]]; do
        i=$((i-1))
    done
    eval "$wstext_posvar=$i"
    wstext-upd
}

wstext-line-end() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    
    local i=$((pos+1))
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    eval "$wstext_posvar=$((i-1))"
}

wstext-line2pos() {
    local line=$1
    local text="${(P)wstext_textvar}"
    local i=1
    local curr=1
    local text_end=${#text}

    while [[ $curr -lt $line && $i -le $text_end ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
    eval "$wstext_posvar=$i"
}

wstext-line-len() {
    local line=$1
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    wstext-line2pos $line "$text"

    local begin=$wstext_pos
    local i=$wstext_pos
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    wstext_linelen=$((i-begin))
}

wstext-pos2line() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local i=1
    local curr=1
    local text_end=${#text}

    while [[ $i -lt $pos && $i -le $text_end ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
    wstext_line=$curr
}

# Sentence functions (end-of-sentence: dot-space-space or dot-newline)
wstext-next-sentence() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"

    # find next alphanumeric character
    pcre_compile -m -x "[[:alnum:]]"
    if pcre_match -b -n $pos -- $text; then
        local b=($=ZPCRE_OP)
        local pos2=$b[1]
    else
        eval "$wstext_posvar=${#text}"
        wstext-upd
        return
    fi

    # find sentence end
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n)"
    if pcre_match -b -n $pos2 -- $text; then
        local b2=($=ZPCRE_OP)
        eval "$wstext_posvar=$b2[1]"
    else
        eval "$wstext_posvar=${#text}"
    fi
    wstext-upd
}

wstext-prev-sentence() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"

    wstext-prev-word $pos "$text"
    local x=$wstext_pos
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n|\Z)[[:punct:][:space:]]*"
    local lastb2=-1
    if pcre_match -b -- $text; then
        while [[ $? -eq 0 ]] do
            local b=($=ZPCRE_OP)
            if [[ $b[1] -gt $x ]]; then
                eval "$wstext_posvar=$lastb2"
                break;
            fi
            lastb2=$b[2]
            pcre_match -b -n $b[2] -- $text
        done
        if [[ ! $lastb2 -eq -1 ]]; then
            eval "$wstext_posvar=$lastb2"
        else
            eval "$wstext_posvar=0"
        fi
    else
        eval "$wstext_posvar=0"
    fi
    wstext-upd
}

wstext-upd() {
    if typeset -f $wstext_updfnvar > /dev/null; then
        $wstext_updfnvar
    fi
}

# Previous paragraph: find previous empty line or start of text
wstext-prev-paragraph() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"

    # find an alnum character
    local i=$pos
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done

    # go to first empty line before $i
    pcre_compile -m -x "\n[[:space:]\\\\]*\n"
    local lastb1=-1
    if pcre_match -b -- $text; then
        while [[ $? -eq 0 ]]; do
            local b=($=ZPCRE_OP)
            ws-debug b1=$b[1] b2=$b[2]
            if [[ $b[1] -gt $i ]]; then
                break
            fi
            lastb1=$b[1]
            pcre_match -b -n $b[2] -- $text
        done
        if [[ $lastb1 -eq -1 ]]; then
            eval "$wstext_posvar=0"
        else
            eval "$wstext_posvar=$((lastb1+1))"
        fi
    else
        eval "$wstext_posvar=0"
    fi
    wstext-upd
}

# Next paragraph: find next empty line or end of text
wstext-next-paragraph() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    # find an alnum character
    local i=$pos
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done

    # go to first empty line before $i
    pcre_compile -m -x "\n[[:space:]\\\\]*\n"
    if pcre_match -b -n $i -- $text; then
        local b=($=ZPCRE_OP)
        eval "$wstext_posvar=$(($b[1]+1))"
    else
        eval "$wstext_posvar=$text_end"
    fi
    wstext-upd
}

# TODO: start document, end document

# Delete character functions
wstext-del-char-left() {
    local pos="$1"
    if [[ $pos -eq 0 ]]; then
        eval "$wstext_posvar=$pos"
    else
        local text="${(P)wstext_textvar}"
        local text_end=${#text}
        ws-defvar $wstext_textvar "$text[1,pos-1]$text[pos+1,text_end]"
        eval "$wstext_posvar=$((pos-1))"
        wstext-upd
    fi
}

wstext-del-char-right() {
    local pos="$1"
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    if [[ $pos -lt $text_end ]]; then
        ws-defvar $wstext_textvar "$text[1,pos]$text[pos+2,text_end]"
    fi
    eval "$wstext_posvar=$((pos))"
    wstext-upd
}

# Delete word functions
wstext-del-word-left() {
    local pos="$1"
    local text="${(P)wstext_textvar}"
    wstext-prev-word $pos "$text"
    local from=$wstext_pos
    local text_end=${#text}
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

# what it does: at word start: delete word, delete all non-printable characters that follow
#               word middle: delete until end of word (do not touch any printable or non-printable characters that follow)
#               non-word printable: delete 1 char + delete non-printable that follow
#               non-word non-printable: delete all non-printable that follow cursor position
wstext-del-word-right() {
    local pos="$1"
    local text="${(P)wstext_textvar}"
    wstext-prev-word $((pos+2)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos
    wstext-next-word $pos "$text"
    local next_word=$wstext_pos
    local text_end=${#text}
    ws-debug pos=$pos word_begin=$word_begin
    if [[ $pos -le $word_begin ]]; then
        wstext-next-printable $word_end "$text"
        local del_end=$wstext_pos
        if [[ $pos -eq 0 && $del_end -eq 0 ]]; then
            ws-defvar $wstext_textvar "$text[2,text_end]"
        else
            ws-defvar $wstext_textvar "$text[1,pos]$text[del_end+1,text_end]"
        fi
    elif [[ $pos -lt $word_end ]]; then
        ws-defvar $wstext_textvar "$text[1,pos]$text[word_end+1,text_end]"
    else
        wstext-next-printable $((pos+1)) "$text"
        local next_printable=$wstext_pos
        if [[ $next_printable -eq $next_word ]]; then
            ws-defvar $wstext_textvar "$text[1,pos]$text[next_printable,text_end]"
        else
            ws-defvar $wstext_textvar "$text[1,pos]$text[next_printable+1,text_end]"
        fi
    fi
    eval "$wstext_posvar=$pos"
    wstext-upd
}

# delete whole word if inside a word and characters and non-printable outside
wstext-del-word() {
    local pos="$1"
    local text="${(P)wstext_textvar}"
    wstext-prev-word $((pos+2)) "$text"
    local word_begin=$wstext_pos
    wstext-end-word $word_begin "$text"
    local word_end=$wstext_pos
    wstext-next-word $pos "$text"
    local to=$wstext_pos
    local text_end=${#text}
    if [[ $pos -lt $word_end ]]; then
        wstext-next-printable $word_end "$text"
        local del_end=$wstext_pos
        local from=$(ws-min $word_begin $pos)
        ws-defvar $wstext_textvar "$text[1,from]$text[del_end+1,text_end]"
        eval "$wstext_posvar=$from"
    else
        wstext-prev-printable $pos "$text"
        local prev_printable=$wstext_pos
        wstext-next-printable $((pos+1)) "$text"
        local next_printable=$wstext_pos
        ws-defvar $wstext_textvar "$text[1,prev_printable]$text[next_printable+1,text_end]"
        eval "$wstext_posvar=$prev_printable"
    fi
    wstext-upd
}

# Delete line functions
wstext-del-line-left() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    wstext-line-start $pos "$text"
    local from=$wstext_pos
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-line-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    wstext-line-start $pos "$text"
    local begin=$wstext_pos
    wstext-line-end $pos "$text"
    local to=$wstext_pos
    if [[ $begin -eq $pos && $to -lt $text_end ]]; then
        ws-defvar $wstext_textvar "$text[1,pos]$text[to+2,text_end]"
    else
        ws-defvar $wstext_textvar "$text[1,pos]$text[to+1,text_end]"
    fi
    eval "$wstext_posvar=$pos"
    wstext-upd    
}

wstext-del-line() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    wstext-line-start $pos "$text"
    local from=$wstext_pos
    wstext-line-end $pos "$text"
    local to=$wstext_pos
    if [[ $to -lt $text_end ]]; then
        ws-defvar $wstext_textvar "$text[1,from]$text[to+2,text_end]"
    else
        ws-defvar $wstext_textvar "$text[1,from]$text[to+1,text_end]"
    fi
    eval "$wstext_posvar=$from"
    wstext-upd    
}

# Delete sentence functions

# get sentence begin / end from the position
wstext-sentence-pos() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local i=1
    while [[ ! "$text[i]" =~ "[[:alnum:]]" && $i -le $text_end ]]; do
        i=$((i+1))
    done
    
    if [[ $pos -lt $((i-1)) || $i -gt $text_end ]]; then
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
            if [[ $b[2] -gt $pos || ($b[2] -eq $pos && $pos -eq $text_end)]]; then
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
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

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
        ws-debug text=\"$text\" from=$from pos=$pos text_end=$text_end
        ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
        eval "$wstext_posvar=$from"
        wstext-upd
    else
        # if in the middle, delete the beginning of the sentence
        ws-defvar $wstext_textvar "$text[1,$sp[1]-1]$text[pos+1,text_end]"
        eval "$wstext_posvar=$(($sp[1]-1))"
        wstext-upd
    fi
}

# deletes from the current position till the stops
wstext-del-sentence-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local sp=($(wstext-sentence-pos $CURSOR $text))

    if [[ ! $sp[1] -eq -1 ]]; then
        ws-defvar $wstext_textvar "$text[1,$pos]$text[$sp[2],text_end]"
        eval "$wstext_posvar=$pos"
        wstext-upd
    else
        eval "$wstext_posvar=$pos"
    fi
}

wstext-del-sentence() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local sp=($(wstext-sentence-pos $CURSOR $text))

    if [[ ! $sp[1] -eq -1 ]]; then
        ws-defvar $wstext_textvar "$text[1,$sp[1]-1]$text[$sp[3],text_end]"
        eval "$wstext_posvar=$(($sp[1]-1))"
        wstext-upd
    else
        eval "$wstext_posvar=$pos"
    fi
}

# Delete paragraph functions
wstext-find-nl-or-eol() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local i=$(ws-min $((pos+1)) $text_end)
    while [[ ! "$text[i]" = $'\n' && $i -lt $text_end ]]; do
        i=$((i+1))
    done
    echo $i
}

wstext-del-paragraph-left() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    wstext-prev-paragraph $pos "$text"
    local from=$(wstext-find-nl-or-eol $wstext_pos "$text")
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-paragraph-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    wstext-next-paragraph $pos "$text"
    local to=$wstext_pos
    ws-defvar $wstext_textvar "$text[1,pos]$text[to,text_end]"
    eval "$wstext_posvar=$pos"
    wstext-upd
}

wstext-del-paragraph() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    wstext-prev-paragraph $pos "$text"
    local from=$wstext_pos

    # find the beginning of the empty line for $to
    wstext-next-paragraph $pos "$text"

    # find the end of the line for the $to
    local i=$wstext_pos
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done

    local to=$i
    ws-defvar $wstext_textvar "$text[1,from]$text[to+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

# Insert functions: insert text after position: !! substitute single quote by "'"...
wstext-insert() {
    local str="$1"
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    if [[ $pos -eq 0 ]]; then
        ws-defvar $wstext_textvar "$str$text"
    else
        ws-defvar $wstext_textvar "$text[1,pos]$str$text[pos+1,${#text}]"
    fi
    eval "$wstext_posvar=$((pos+${#str}))"
    wstext-upd
}
