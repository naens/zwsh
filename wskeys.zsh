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
    unset ws_text
}

# History keys
bindkey -M zsh-ws "^E" up-line-or-history
bindkey -M zsh-ws "^X" down-line-or-history

# Cursor Move: character
bindkey -M zsh-ws "^S" backward-char
bindkey -M zsh-ws "^D" forward-char

# Cursor Move: word
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

# Cursor move: line
zle -N ws-line-start
bindkey -M zsh-ws "^Qs" ws-line-start
bindkey -M zsh-ws "^QS" ws-line-start
ws-line-start() {
    wstext-line-start $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

zle -N ws-line-end
bindkey -M zsh-ws "^Qd" ws-line-end
bindkey -M zsh-ws "^QD" ws-line-end
ws-line-end() {
    wstext-line-end $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

# Cursor move: sentence
zle -N ws-prev-sentence
bindkey -M zsh-ws "^Os" ws-prev-sentence
bindkey -M zsh-ws "^OS" ws-prev-sentence
ws-prev-sentence() {
    wstext-prev-sentence $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

zle -N ws-next-sentence
bindkey -M zsh-ws "^Od" ws-next-sentence
bindkey -M zsh-ws "^OD" ws-next-sentence
ws-next-sentence() {
    wstext-next-sentence $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

# Cursor move: paragraph
zle -N ws-prev-paragraph
bindkey -M zsh-ws "^O^S" ws-prev-paragraph
ws-prev-paragraph() {
    wstext-prev-paragraph $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

zle -N ws-next-paragraph
bindkey -M zsh-ws "^O^D" ws-next-paragraph
ws-next-paragraph() {
    wstext-next-paragraph $CURSOR "$ws_text"
    CURSOR=$wstext_pos
}

# name of the variable containing the text
wstext_textvar=ws_text
wstext_updfnvar=ws-updfn

ws-updfn() {
    BUFFER="$ws_text"
}

zle -N ws-testfun
bindkey -M zsh-ws "^[=" ws-testfun
ws-testfun() {
    local sp=($(wstext-sentence-pos $CURSOR $ws_text))
    if [[ ! $sp[1] -eq -1 ]]; then
        ws-debug sp1=$sp[1] \"$ws_text[$sp[1]]\"
        ws-debug sp2=$sp[2] \"$ws_text[$sp[2]]\"
        ws-debug sp3=$sp[3] \"$ws_text[$sp[3]]\"
    fi
}

zle -N ws-testfun2
bindkey -M zsh-ws "^[\\\\" ws-testfun2
ws-testfun2() {
    wstext-del-sentence-right $CURSOR ws_text
    if [[ -n $wstext_pos ]]; then
        CURSOR=$wstext_pos
    fi
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

# Insert Keys
zle -N ws-self-insert
bindkey -M zsh-ws -R "!"-"~" ws-self-insert
bindkey -M zsh-ws " " ws-self-insert
ws-self-insert() {
    wstext-insert $CURSOR $KEYS ws_text
    CURSOR=$wstext_pos
}

zle -N ws-split-line
bindkey -M zsh-ws "^N" ws-split-line
ws-split-line() {
    wstext-insert $CURSOR \\$'\n' ws_text
    CURSOR=$wstext_pos
}

zle -N ws-kr
bindkey -M zsh-ws "^Kr" ws-kr
bindkey -M zsh-ws "^KR" ws-kr
ws-kr() {
    wsdialog_krdial-run
}

zle -N ws-bracketed-paste
bindkey -M zsh-ws "^[[200~" ws-bracketed-paste
ws-bracketed-paste() {
    local ws_pasted_text="$zle_bracketed_paste"
    zle bracketed-paste ws_pasted_text
    ws-debug pasted text is \"$ws_pasted_text\"
    wstext-insert $CURSOR $ws_pasted_text ws_text
    CURSOR=$wstext_pos
    #TODO: select (kb-kk), insert into kill ring...
}

# Delete keys: char
zle -N ws-del-char-left
bindkey -M zsh-ws "^H" ws-del-char-left
ws-del-char-left() {
    wstext-del-char-left $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-del-char-right
bindkey -M zsh-ws "^G" ws-del-char-right
ws-del-char-right() {
    wstext-del-char-right $CURSOR ws_text
    CURSOR=$wstext_pos
}

# Delete keys: word
zle -N ws-del-word-right
bindkey -M zsh-ws "^T" ws-del-word-right
ws-del-word-right() {
    wstext-del-word-right $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-del-word-left
bindkey -M zsh-ws "^[h" ws-del-word-left
bindkey -M zsh-ws "^[H" ws-del-word-left
ws-del-word-left() {
    wstext-del-word-left $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-del-word
bindkey -M zsh-ws "^[y" ws-del-word
bindkey -M zsh-ws "^[Y" ws-del-word
ws-del-word() {
    wstext-del-word $CURSOR ws_text
    CURSOR=$wstext_pos
}

# Delete keys: line
zle -N ws-del-line-left
bindkey -M zsh-ws "^Q^H" ws-del-line-left
ws-del-line-left() {
    wstext-del-line-left $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-del-line-right
bindkey -M zsh-ws "^Qy" ws-del-line-right
bindkey -M zsh-ws "^QY" ws-del-line-right
ws-del-line-right() {
    wstext-del-line-right $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-del-line
bindkey -M zsh-ws "^Y" ws-del-line
ws-del-line() {
    wstext-del-line $CURSOR ws_text
    CURSOR=$wstext_pos
}

# Delete keys: sentence
zle -N ws-ws-del-sentence-left
bindkey -M zsh-ws "^Oh" ws-ws-del-sentence-left
bindkey -M zsh-ws "^OH" ws-ws-del-sentence-left
ws-ws-del-sentence-left() {
    wstext-del-sentence-left $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-ws-del-sentence-right
bindkey -M zsh-ws "^Og" ws-ws-del-sentence-right
bindkey -M zsh-ws "^OG" ws-ws-del-sentence-right
ws-ws-del-sentence-right() {
    wstext-del-sentence-right $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-ws-del-sentence
bindkey -M zsh-ws "^Oy" ws-ws-del-sentence
bindkey -M zsh-ws "^OY" ws-ws-del-sentence
ws-ws-del-sentence() {
    wstext-del-sentence $CURSOR ws_text
    CURSOR=$wstext_pos
}

# Delete keys: paragraph
zle -N ws-ws-del-paragraph-left
bindkey -M zsh-ws "^O^H" ws-ws-del-paragraph-left
ws-ws-del-paragraph-left() {
    wstext-del-paragraph-left $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-ws-del-paragraph-right
bindkey -M zsh-ws "^O^G" ws-ws-del-paragraph-right
ws-ws-del-paragraph-right() {
    wstext-del-paragraph-right $CURSOR ws_text
    CURSOR=$wstext_pos
}

zle -N ws-ws-del-paragraph
bindkey -M zsh-ws "^O^Y" ws-ws-del-paragraph
ws-ws-del-paragraph() {
    wstext-del-paragraph $CURSOR ws_text
    CURSOR=$wstext_pos
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

bindkey -M zsh-ws "^Ql" wskwtest
zle -N wskwtest
wskwtest() {
    wsblock_text=blabla
    wsdialog_kwdial-run
}

zle -N zle-line-pre-redraw
zle-line-pre-redraw () {
#    ws-debug KEYMAP=$KEYMAP BUFFER=$BUFFER state=$ZLE_STATE
    local modefun=$KEYMAP-pre-redraw
    if typeset -f $modefun > /dev/null; then
        $modefun
    fi
}

main-pre-redraw() {
    ws_text="$BUFFER" # TODO: on tab expand: redefine ws_text
#    ws-updfn # temporary
#    echo MAIN buffer="$BUFFER" > $debugfile
}
