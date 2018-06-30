bindkey -N wsdinfo

wsdinfo-restore() {
    CURSOR=$wsdinfo_saved_curs
    BUFFER[$wsdinfo_saved_length+1,${#BUFFER}]=""
}

wsdinfo-undef() {
    unset wsdinfo_saved_curs
    unset wsdinfo_saved_length
    unset wsdinfo_endfn
}

zle -N wsdinfo-end
bindkey -M wsdinfo "^[" wsdinfo-end
wsdinfo-end() {
    if [[ -n "$wsdinfo_endfn" ]]; then
        $wsdinfo_endfn
    fi
    wsdinfo-restore
    wsdinfo-undef
    zle -K $wsdinfo_saved_keymap
}

wsdinfo-run() {
    wsdinfo_saved_curs=$CURSOR
    local length=${#BUFFER}
    wsdinfo_saved_length=$length
    wsdinfo_endfn="$1"
    wsdinfo_saved_keymap=$KEYMAP
    local l1="$wsdinfo_l1"$'\n'
    local l2="$wsdinfo_l2"$'\n'
    local l3="$wsdinfo_l3"
    ws-insert-formatted-at $length $'\n'"$l1$l2$l3"
    zle -K wsdinfo
}
