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

wstext-prev-word() {
    local pos=${(P)wstext_posvar}

    local prev=$(wstxtfun-prev-word $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$prev"
    wstext-upd
}

wstext-next-word() {
    local pos=${(P)wstext_posvar}

    local next=$(wstxtfun-next-word $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$next"
    wstext-upd
}

wstext-end-word() {
    local pos=${(P)wstext_posvar}

    local end_word=$(wstxtfun-end-word $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$end_word"
    wstext-upd
}

# Line functions
wstext-line-start() {
    local pos=${(P)wstext_posvar}

    local line_start=$(wstxtfun-line-start $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$line_start"
    wstext-upd
}

wstext-line-end() {
    local pos=${(P)wstext_posvar}

    local line_end=$(wstxtfun-line-end $pos "${(P)wstext_textvar}")    

    eval "$wstext_posvar=$line_end"
    wstext-upd
}

# Sentence functions (end-of-sentence: dot-space-space or dot-newline)
wstext-prev-sentence() {
    local pos=${(P)wstext_posvar}

    local prev_sentence_pos=$(wstxt-prev-sentence $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$prev_sentence_pos"
    wstext-upd
}

wstext-next-sentence() {
    local pos=${(P)wstext_posvar}

    local next_sentece_pos=$(wstxt-next-sentence $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$next_sentence_pos"
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

    local prev_paragraph_pos=$(wstxtfun-prev-paragraph-pos $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$prev_paragraph_pos"
    wstext-upd
}

# Next paragraph: find next empty line or end of text
wstext-next-paragraph() {
    local pos=${(P)wstext_posvar}

    local next_paragraph_pos=$(wstxtfun-next-paragraph $pos "${(P)wstext_textvar}")

    eval "$wstext_posvar=$next_paragraph_pos"
    wstext-upd
}

# TODO: start document, end document

# Delete character functions
wstext-del-char-left() {
    local pos=${(P)wstext_posvar}
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
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    if [[ $pos -lt $text_end ]]; then
        ws-defvar $wstext_textvar "$text[1,pos]$text[pos+2,text_end]"
    fi
    eval "$wstext_posvar=$pos"
    wstext-upd
}

# Delete word functions
wstext-del-word-left() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    local from=$(wstxtfun-prev-word $pos "$text")
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

# what it does: at word start: delete word, delete all non-printable characters that follow
#               word middle: delete until end of word (do not touch any printable or non-printable characters that follow)
#               non-word printable: delete 1 char + delete non-printable that follow
#               non-word non-printable: delete all non-printable that follow cursor position
wstext-del-word-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local word_begin=$(wstxtfun-prev-word $((pos+2)) "$text")
    local word_end=$(wstxtfun-end-word $word_begin "$text")
    local next_word=$(wstxtfun-next-word $pos "$text")
    local text_end=${#text}
    if [[ $pos -le $word_begin ]]; then
        local del_end=$(wstxtfun-next-printable $word_end "$text")
        ws-debug DEL_WORD_RIGHT: pos=$pos word_begin=$word_begin del_end=$del_end
        if [[ $pos -eq 0 && $del_end -eq 0 ]]; then
            ws-defvar $wstext_textvar "$text[2,text_end]"
        else
            ws-defvar $wstext_textvar "$text[1,pos]$text[del_end+1,text_end]"
        fi
    elif [[ $pos -lt $word_end ]]; then
        ws-defvar $wstext_textvar "$text[1,pos]$text[word_end+1,text_end]"
    else
        local next_printable=$(wstxtfun-next-printable $((pos+1)) "$text")
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
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local word_begin=$(wstxtfun-prev-word $((pos+2)) "$text")
    local word_end=$(wstxtfun-end-word $word_begin "$text")
    local to=$(wstxtfun-next-word $pos "$text")
    local text_end=${#text}
    if [[ $pos -lt $word_end ]]; then
        local del_end=$(wstxtfun-next-printable $word_end "$text")
        local from=$(ws-min $word_begin $pos)
        ws-defvar $wstext_textvar "$text[1,from]$text[del_end+1,text_end]"
        eval "$wstext_posvar=$from"
    else
        local prev_printable=$(wstxtfun-prev-printable $pos "$text")
        local next_printable=$(wstxt-next-printable $((pos+1)) "$text")
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
    local from=$(wstxtfun-line-start $pos "$text")
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-line-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    local begin=$(wstxtfun-line-start $pos "$text")
    local to=$(wstext-line-end $pos "$text")
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
    local from=$(wstxtfun-line-start $pos "$text")
    local to=$(wstxtfun-line-end $pos "$text")
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
        local from=$(wstxtfun-prev-sentence "$text")
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
wstext-del-paragraph-left() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local prevp=$(wstxtfun-prev-paragraph $pos "$text")
    local from=$(wstxtfun-line-end $prevp "$text")
    ws-defvar $wstext_textvar "$text[1,from]$text[pos+1,text_end]"
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-paragraph-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local to=$(wstxtfun-next-paragraph $pos "$text")
    ws-defvar $wstext_textvar "$text[1,pos]$text[to,text_end]"
    eval "$wstext_posvar=$pos"
    wstext-upd
}

wstext-del-paragraph() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local from=$(wstxtfun-prev-paragraph $pos "$text")

    # find the beginning of the empty line for $to
    local next_paragraph=$(wstxtfun-next-paragraph $pos "$text")

    # find the end of the line for the $to
    local i=next_paragraph
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
