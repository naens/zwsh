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

wstext-jump-lines() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    local jump=$1
    local nlines=$2
    local line_begin=$3

    local ws_row
    local ws_col
    read ws_row ws_col <<< $(wstxtfun-pos $pos "$text")

    local new_row=$((ws_row+jump))
    if [[ $new_row -lt 0 ]]; then
        ws-debug WSTEXT_JUMP_LINES: BAD ARGUMENT: jump back too big: jump=$jump
        new_row=0
    elif [[ $new_row -gt $nlines ]]; then
        ws-debug WSTEXT_JUMP_LINES: BAD ARGUMENT: jump forward too big: jump=$jump
        new_row=$nlines
    fi

    if [[ -n $line_begin ]]; then
        ws_col=1
    fi
    if [[ $nlines -ge $new_row ]]; then
        local new_pos=$(wstxtfun-yx-pos $new_row $ws_col "$text")
        eval "$wstext_posvar=$new_pos"
        wstext-upd
    fi
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

# start document
wstext-start-document() {
    eval "$wstext_posvar=0"
    wstext-upd
}

# end document
wstext-end-document() {
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    eval "$wstext_posvar=$text_end"
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
        wstext-delete $pos $pos
        eval "$wstext_posvar=$((pos-1))"
        wstext-upd
    fi
}

wstext-del-char-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    if [[ $pos -lt $text_end ]]; then
        wstext-delete $((pos+1)) $((pos+1))
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
    wstext-delete $((from+1)) $((pos))
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
            wstext-delete 0 1
        else
            wstext-delete $((pos+1)) $del_end
        fi
    elif [[ $pos -lt $word_end ]]; then
        wstext-delete $((pos+1)) $word_end
    else
        local next_printable=$(wstxtfun-next-printable $((pos+1)) "$text")
        if [[ $next_printable -eq $next_word ]]; then
            wstext-delete $((pos+1)) $((next_printable-1))
        else
            wstext-delete $((pos+1)) $((next_printable))
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
        wstext-delete $((from+1)) $((del_end))
        eval "$wstext_posvar=$from"
    else
        local prev_printable=$(wstxtfun-prev-printable $pos "$text")
        local next_printable=$(wstxt-next-printable $((pos+1)) "$text")
        wstext-delete $((prev_printable+1)) $((next_printable))
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
    wstext-delete $((from+1)) $pos
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-line-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}
    local begin=$(wstxtfun-line-start $pos "$text")
    local to=$(wstxtfun-line-end $pos "$text")
    if [[ $begin -eq $pos && $to -lt $text_end ]]; then
        wstext-delete $((pos+1)) $((to+1))
    else
        wstext-delete $((pos+1)) $to
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
        wstext-delete $((from+1)) $((to+1))
    else
        wstext-delete $((from+1)) $to
    fi
    eval "$wstext_posvar=$from"
    wstext-upd    
}

# Delete sentence functions
wstext-del-sentence-left() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    # getting the positions of the current sentence
    local sp=($(wstxtfun-sentence-pos $pos "$text"))

    # return if outside of any sentence
    if [[ $sp[1] -eq -1 ]]; then
        unset wstext_pos
        return
    fi

    # if at the beginning, delete previous sentence
    if [[ $((pos+1)) -eq $sp[1] && $pos -gt 0 ]]; then
        ws-debug DEL_SENTENCE_LEFT: Delete Previous Sentence
        local from=$(wstxtfun-prev-sentence $pos "$text")
        ws-debug text=\"$text\" from=$from pos=$pos text_end=$text_end
        wstext-delete $((from+1)) $pos
        eval "$wstext_posvar=$from"
        wstext-upd
    else
        # if in the middle, delete the beginning of the sentence
        wstext-delete $sp[1] $pos
        eval "$wstext_posvar=$(($sp[1]-1))"
        wstext-upd
    fi
}

# deletes from the current position till the stops
wstext-del-sentence-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local sp=($(wstxtfun-sentence-pos $pos "$text"))

    if [[ ! $sp[1] -eq -1 ]]; then
        wstext-delete $((pos+1)) $((sp[2]-1))
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

    local sp=($(wstxtfun-sentence-pos $pos "$text"))

    if [[ ! $sp[1] -eq -1 ]]; then
        wstext-delete $sp[1] $((sp[3]-1))
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

    wstext-delete $((from+1)) $pos
    eval "$wstext_posvar=$from"
    wstext-upd
}

wstext-del-paragraph-right() {
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    local text_end=${#text}

    local to=$(wstxtfun-next-paragraph $pos "$text")

    wstext-delete $((pos+1)) $((to-1))
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

    wstext-delete $((from+1)) $to
    eval "$wstext_posvar=$from"
    wstext-upd
}

# marks insert/delete functions
wstext-marks-move-insert() {
    local pos=$1
    local len=$2
    ws-debug MARKS_MOVE_INSERT: pos=$pos len=$len
    ws-debug MARKS_MOVE_INSERT: wstext_marksvar=${(P)wstext_marksvar}
    declare -A marks
    marks=(${(@Pkv)wstext_marksvar})
    for m_name m_pos in "${(@kv)marks}"; do
#        ws-debug MARKS_MOVE_INSERT: m_name=$m_name m_pos=$m_pos
        if [[ $m_pos -gt $pos ]]; then
#            ws-debug MARKS_MOVE_INSERT: move mark $m_name from $m_pos to $((m_pos+len))
            eval ${wstext_marksvar}"[$m_name]"=$((m_pos+len))
        fi
    done
}

wstext-marks-move-delete() {
    local pos=$1
    local len=$2
    ws-debug MARKS_MOVE_DELETE: pos=$pos len=$len
    declare -A marks
    marks=(${(@Pkv)wstext_marksvar})
    for m_name m_pos in "${(@kv)marks}"; do
        ws-debug MARKS_MOVE_DELETE: m_name=$m_name m_pos=$m_pos
        if [[ $m_pos -lt $pos ]]; then
            continue
        elif [[ $m_pos -lt $((pos+len)) ]]; then
            ws-debug MARKS_MOVE_DELETE'[1]': move mark $m_name from $m_pos to $pos
            eval ${wstext_marksvar}"[$m_name]"=$pos
        else
            ws-debug MARKS_MOVE_DELETE'[2]': move mark $m_name from $m_pos to $((m_pos-len))
            eval ${wstext_marksvar}"[$m_name]"=$((m_pos-len))
        fi
    done
}

# Insert function
wstext-insert() {
    local str="$1"
    local pos=${(P)wstext_posvar}
    local text="${(P)wstext_textvar}"
    if [[ $pos -eq 0 ]]; then
        ws-defvar $wstext_textvar "$str$text"
    else
        ws-defvar $wstext_textvar "$text[1,pos]$str$text[pos+1,${#text}]"
    fi
    wstext-marks-move-insert $pos ${#str}
    eval "$wstext_posvar=$((pos+${#str}))"
    wstext-upd
}

wstext-delete() {
    local from=$1
    local to=$2
    local text="${(P)wstext_textvar}"
    local text_len=${#text}

    wsblock-delupd $((from-1)) $to

    ws-debug WSTEXT_DELETE: from=$from to=$to
    wstext-marks-move-delete $((from-1)) $((to-from+1))
    if [[ $((to-from)) -gt 1 ]]; then
        ws_delbuf="$text[from, to]"
    fi

    if [[ $from -eq 0 ]]; then
        if [[ $to -lt $((text_len)) ]]; then
            ws-defvar $wstext_textvar "$text[to+1,text_len]"
        fi
    else
        if [[ $to -eq $((text_len)) ]]; then
            ws-defvar $wstext_textvar "$text[1,from-1]"
        else
            ws-defvar $wstext_textvar "$text[1,from-1]$text[to+1,text_len]"
        fi
    fi
}
