# character functions
ws-txtfun-prev-printable() {
    local pos=$1
    local text="$2"
    local text_end=${#text}

    local i=$pos
    while [[ ! "$text[i]" =~ [[:graph:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    echo $i
}

wstxtfun-next-printable() {
    local pos=$1
    local text="$2"
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
    echo $(ws-min $((i-1)) $text_end)
}

wstxtfun-line2pos() {
    local line=$1
    local text="$2"
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
    local text="$2"

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
    local text="$2"
    local text_end=${#text}

    local begin=$(wstext-line2pos $line "$text")
    local i=$begin
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-begin))
}


# sentence functions
wstxtfun-prev-sentence() {
    local pos=$1
    local text="$2"

    local x=$(wstxtfun-prev-word $pos "$text")
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n|\Z)[[:punct:][:space:]]*"
    local lastb2=-1
    if pcre_match -b -- $text; then
        while [[ $? -eq 0 ]] do
            local b=($=ZPCRE_OP)
            if [[ $b[1] -gt $x ]]; then
                echo $lastb2
                break;
            fi
            lastb2=$b[2]
            pcre_match -b -n $b[2] -- $text
        done
        if [[ ! $lastb2 -eq -1 ]]; then
            echo $lastb2
        else
            echo 0
        fi
    else
        echo 0
    fi
}

wstxtfun-next-sentence() {
    local pos=$1
    local text="$2"
    # find next alphanumeric character
    pcre_compile -m -x "[[:alnum:]]"
    if pcre_match -b -n $pos -- $text; then
        local b=($=ZPCRE_OP)
        local pos2=$b[1]
    else
        echo ${#text}
        return
    fi

    # find sentence end
    pcre_compile -m -x "(\\.|!|\\?)[[:punct:][:space:]]*(\s{2}|\t|\n)"
    if pcre_match -b -n $pos2 -- $text; then
        local b2=($=ZPCRE_OP)
        echo $b2[1]
    else
        echo ${#text}
    fi
}


# paragraph functions
wstxtfun-prev-paragraph() {
    local pos=$1
    local text="$2"

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
            echo 0
        else
            echo $((lastb1+1))
        fi
    else
        echo 0
    fi
}

wstxtfun-next-paragraph() {
    local pos=$1
    local text="$2"
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
        echo $(($b[1]+1))
    else
        echo $text_end
    fi
}
 