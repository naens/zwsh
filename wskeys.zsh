# file contains all keybindings, calls function depending
# on the state

bindkey -N zsh-ws
bindkey -M zsh-ws -R " "-"~" self-insert

# state variables:
# * $kb & !$kk: defining selection
# * $kb & $kk: selection defined
# * $kw=1: (write file) filename input state
# * $kw=2: (write file) file exists warning
# * $kw=3: (write file) error writing file warning
# * $qf: performing history search
# * $kr=1: (import) filename input state
# * $kr=2: (import) error file does not exist (or not readable)
zle -N zle-line-init
# init: on display of new line
zle-line-init() {
    # unset all variables on accept / interrupt
    unset kb
    unset kk
    unset kw
    unset qf
    unset kr
    unset ws_select
    unset region_highlight
}

# Cursor Keys
bindkey -M zsh-ws "^E" up-line-or-history
bindkey -M zsh-ws "^X" down-line-or-history
bindkey -M zsh-ws "^S" backward-char
bindkey -M zsh-ws "^D" forward-char
bindkey -M zsh-ws "^Qs" beginning-of-line
bindkey -M zsh-ws "^QS" beginning-of-line
bindkey -M zsh-ws "^Qd" end-of-line
bindkey -M zsh-ws "^QD" end-of-line
#bindkey -M zsh-ws "^A" backward-word
#bindkey -M zsh-ws "^F" forward-word

# name of the variable containing the text
wstext_textvar=ws_text
wstext_updfnvar=ws-updfn

ws-updfn() {
    ws_text="$BUFFER"
}

zle -N ws-word-left
bindkey -M zsh-ws "^A" ws-word-left
ws-word-left() {
    wstext-prev-word $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}
    
zle -N ws-word-right
bindkey -M zsh-ws "^F" ws-word-right
ws-word-right() {
    wstext-next-word $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

zle -N ws-start-doc
bindkey -M zsh-ws "^R" ws-start-doc
ws-start-doc() {
    CURSOR=0
}

zle -N ws-end-doc
bindkey -M zsh-ws "^C" ws-end-doc
ws-end-doc() {
    CURSOR=${#BUFFER}
}

bindkey -M zsh-ws "^Q^[" undefined-key
bindkey -M zsh-ws "^K^[" undefined-key
bindkey -M zsh-ws "^[" send-break

#bindkey "^B" TODO: align?

# Insert Keys
zle -N ws-split-line
bindkey -M zsh-ws "^N" ws-split-line
ws-split-line() {
    LBUFFER+=\\$'\n'
}

zle -N ws-kr
bindkey -M zsh-ws "^Kr" ws-kr
bindkey -M zsh-ws "^KR" ws-kr
ws-kr() {
    wsdialog_krdial-run
}

# TODO: remove standout OR integrate with blocks
bindkey -M zsh-ws "^[[200~" bracketed-paste


# Delete Keys
bindkey -M zsh-ws "^G" delete-char-or-list
bindkey -M zsh-ws "^H" backward-delete-char
bindkey -M zsh-ws "^?" backward-delete-char
bindkey -M zsh-ws "^Y" kill-whole-line
bindkey -M zsh-ws "^T" kill-word
bindkey -M zsh-ws "^[h" backward-kill-word
bindkey -M zsh-ws "^[H" backward-kill-word
bindkey -M zsh-ws "^[y" delword
bindkey -M zsh-ws "^[Y" delword
bindkey -M zsh-ws "^Qy" kill-line
bindkey -M zsh-ws "^QY" kill-line
bindkey -M zsh-ws "^Q^H" backward-kill-line

zle -N delword
delword() {
    zle forward-word
    zle backward-word
    zle delete-word
    if [[ $BUFFER[CURSOR] =~ [[:space:]] ]]; then
	zle delete-char
    fi
}

# Block Keys
#zle -N ws-kb
#bindkey -M zsh-ws "^Kb" ws-kb
#bindkey -M zsh-ws "^KB" ws-kb

zle -N ws-insert-saved
bindkey -M zsh-ws "^Kc" ws-insert-saved
bindkey -M zsh-ws "^KC" ws-insert-saved
bindkey -M zsh-ws "^Kv" ws-insert-saved
bindkey -M zsh-ws "^KV" ws-insert-saved
# on ^Kc/^Kv insert saved substring if exists and nothing selected
ws-insert-saved() {
    if [[ -n $ws_saved ]]; then
	kb=$CURSOR
	kk=$(( $CURSOR + ${#ws_saved} ))
	LBUFFER+=$ws_saved
	CURSOR=$(( $CURSOR + ${#ws_saved} ))
	zle -K wsblock
	wsblock-upd
    fi
}

# Undo Keys
bindkey -M zsh-ws "^U" undo
bindkey -M zsh-ws "^6" redo

# Other Keys
bindkey -M zsh-ws "^M" accept-line
bindkey -M zsh-ws "^J" run-help
bindkey -M zsh-ws "^V" overwrite-mode
bindkey -M zsh-ws "^I" expand-or-complete

# testing dialog
debugfile=/dev/pts/4
if [[ ! -e $debugfile ]]; then
    debugfile=/dev/null
fi
debugfile=/dev/null

bindkey -M zsh-ws "^Ql" wskwtest
zle -N wskwtest
wskwtest() {
    wsblock_text=blabla
    wsdialog_kwdial-run
}

zle -N zle-line-pre-redraw
zle-line-pre-redraw () {
    local modefun=$KEYMAP-pre-redraw
    if typeset -f $modefun > /dev/null; then
        $modefun
    fi
}

main-pre-redraw() {
    ws-updfn # temporary
    echo MAIN buffer="$BUFFER" > $debugfile
}
