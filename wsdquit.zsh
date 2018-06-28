bindkey -N wsdquit

wsdquit-restore() {
    CURSOR=$wsdquit_saved_curs
    BUFFER[$wsdquit_saved_length+1,${#BUFFER}]=""
}

wsdquit-undef() {
    unset wsdquit_saved_curs
    unset wsdquit_saved_length
    unset wsdquit_yes
    unset wsdquit_no
}

zle -N wsdquit-yes
bindkey -M wsdquit "Y" wsdquit-yes
bindkey -M wsdquit "y" wsdquit-yes
wsdquit-yes() {
    if [[ -n "$wsdquit_yes" ]]; then
        $wsdquit_yes
    fi
    wsdquit-restore
    wsdquit-undef
    zle -K $wsdquit_saved_keymap
}

zle -N wsdquit-no
bindkey -M wsdquit "N" wsdquit-no
bindkey -M wsdquit "n" wsdquit-no
wsdquit-no() {
    if [[ -n "$wsdquit_no" ]]; then
        $wsdquit_no
    fi
    wsdquit-restore
    wsdquit-undef
    zle -K $wsdquit_saved_keymap
}

# prints quit dialog, asks for confirmation, returns true or false
wsdquit-run() {
    wsdquit_saved_curs=$CURSOR
    local length=${#BUFFER}
    wsdquit_saved_length=$length
    wsdquit_yes="$1"
    wsdquit_no="$2"
    wsdquit_saved_keymap=$KEYMAP
    l1="*Modifications have just been made.*"
    l3="Are you sure you want to abandon them (Y/N)?"
    ws-insert-formatted-at $length $'\n'"$l1"$'\n'$'\n'"$l3"
    zle -K wsdquit
}
