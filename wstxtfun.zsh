# character functions
ws-txtfun-prev-printable() {
    local pos=$1
    local text="$text"
    local text_end=${#text}

    local i=$pos
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    echo $i
}

wstxtfun-next-printable() {
    local pos=$1
    local text="$text"
    local text_end=${#text}

    local i=$((pos+1))
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-1))
}

# word functions
wstxtfun-prev-word() {
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
    echo $i
}

wstxtfun-next-word() {
    local pos=$1
    local text="$2"
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
    echo $((i-1))
}

wstxtfun-end-word() {
    local pos=$1
    local text="$2"
    local text_end=${#text}

    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-1))
}

# line functions
wstxtfun-line-start() {
    local pos=$1
    local text="$2"
    
    local i=$pos
    while [[ ! "$text[i]" = $'\n' && $i -ge 1 ]]; do
        i=$((i-1))
    done
    echo $i
}

wstxtfun-line-end() {
    local pos=$1
    local text="$2"
    local text_end=${#text}
    
    local i=$((pos+1))
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-1))
}

wstxtfun-line2pos() {
    local line=$1
    local text="$text"
    local i=1
    local curr=1
    local text_end=${#text}

    while [[ $curr -lt $line && $i -le $text_end ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
    echo $i
}

wstxtfun-pos2line() {
    local pos=$1
    local text="$text"
    local i=1
    local curr=1
    local text_end=${#text}

    while [[ $i -lt $pos && $i -le $text_end ]]; do
        if [[ "$text[i]" = $'\n' ]]; then
            curr=$((curr+1))
        fi
        i=$((i+1))
    done
     echo $curr
}

wstxtfun-line-len() {
    local line=$1
    local text="$text"
    local text_end=${#text}

    local begin=$(wstext-line2pos $line "$text")
    local i=$begin
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-begin))
}


# sentence functions

# paragraph functions
