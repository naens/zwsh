# text navigation functions: return result in echo form, do not modify content.
# functions without global variables, in order to facilitate testing
# the wstext.zsh file should contain only current text modification functions,
# whereas wstxtnav.zsh only more abstract helper functions.

wstxtnav-prev-alnum() {
    local pos=$1
    local text="$2"
    local i=$pos
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i-1))
    done
    if [[ $i -lt 1 ]]; then
        echo -1
    else
        echo $i
    fi
}

wstxtnav-next-alnum() {
    local pos=$1
    local text="$2"
    local text_end=${#text}
    local i=$((pos+1))
    while [[ ! "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    if [[ $i -gt $text_end ]]; then
        echo -1
    else
        echo $((i-1))
    fi
}

wstxtnav-prev-word() {
}

wstxtnav-next-word() {
}

wstextnav-start-word() {
    local pos=$1
    local text="$2"

    local i=$pos
    while [[ "$text[i]" =~ [[:alnum:]] && $i -ge 1 ]]; do
        i=$((i+1))
    done
    echo $i
}

wstextnav-end-word() {
    local pos=$1
    local text="$2"
    local text_end=${#text}

    local i=$((pos+1))
    while [[ "$text[i]" =~ [[:alnum:]] && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-1))
}

wstextnav-start-line() {
    local pos=$1
    local text="$2"
    
    local i=$pos
    while [[ ! "$text[i]" = $'\n' && $i -ge 1 ]]; do
        i=$((i-1))
    done
    echo $i
}

wstextnav-end-line() {
    local pos=$1
    local text="$2"
    local text_len=${#text}
    
    local i=$pos
    while [[ ! "$text[i]" = $'\n' && $i -le $text_len ]]; do
        i=$((i+1))
    done
    echo $((i-1))
}

wstextnav-line2pos() {
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

wstext-line-len() {
    local line=$1
    local text="$2"
    local text_end=${#text}

    wstext-line2pos $line "$text"

    local begin=$wstext_pos
    local i=$wstext_pos
    while [[ ! "$text[i]" = $'\n' && $i -le $text_end ]]; do
        i=$((i+1))
    done
    echo $((i-begin))
}

wstext-pos2line() {
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


wstextnav-start-sentence() {
}

wstextnav-end-sentence() {
}

wstextnav-prev-empty-line() {
}

wstextnav-next-empty-line() {
}
