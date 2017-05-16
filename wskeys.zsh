# file contains all keybindings, calls function depending
# on the state

bindkey -N wskeys
bindkey -M wskeys -R " "-"~" self-insert

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
bindkey -M wskeys "^E" up-line-or-history
bindkey -M wskeys "^X" down-line-or-history

# Cursor Move: character
bindkey -M wskeys "^S" backward-char
bindkey -M wskeys "^D" forward-char

# Cursor Move: word
zle -N ws-word-left
bindkey -M wskeys "^A" ws-word-left
ws-word-left() {
    wstext-prev-word $CURSOR
    CURSOR=$wstext_pos
}
    
zle -N ws-word-right
bindkey -M wskeys "^F" ws-word-right
ws-word-right() {
    wstext-next-word $CURSOR
    CURSOR=$wstext_pos
}

# Cursor move: line
zle -N ws-line-start
bindkey -M wskeys "^Qs" ws-line-start
bindkey -M wskeys "^QS" ws-line-start
ws-line-start() {
    wstext-line-start $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-line-end
bindkey -M wskeys "^Qd" ws-line-end
bindkey -M wskeys "^QD" ws-line-end
ws-line-end() {
    wstext-line-end $CURSOR
    CURSOR=$wstext_pos
}

# Cursor move: sentence
zle -N ws-prev-sentence
bindkey -M wskeys "^Os" ws-prev-sentence
bindkey -M wskeys "^OS" ws-prev-sentence
ws-prev-sentence() {
    wstext-prev-sentence $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-next-sentence
bindkey -M wskeys "^Od" ws-next-sentence
bindkey -M wskeys "^OD" ws-next-sentence
ws-next-sentence() {
    wstext-next-sentence $CURSOR
    CURSOR=$wstext_pos
}

# Cursor move: paragraph
zle -N ws-prev-paragraph
bindkey -M wskeys "^O^S" ws-prev-paragraph
ws-prev-paragraph() {
    wstext-prev-paragraph $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-next-paragraph
bindkey -M wskeys "^O^D" ws-next-paragraph
ws-next-paragraph() {
    wstext-next-paragraph $CURSOR
    CURSOR=$wstext_pos
}

# name of the variable containing the text
wstext_textvar=ws_text
wstext_updfnvar=ws-updfn

ws-updfn() {
    BUFFER="$ws_text"
}

zle -N ws-testfun
bindkey -M wskeys "^[=" ws-testfun
ws-testfun() {
    local sp=($(wstext-sentence-pos $CURSOR))
    if [[ ! $sp[1] -eq -1 ]]; then
        ws-debug sp1=$sp[1] \"$ws_text[$sp[1]]\"
        ws-debug sp2=$sp[2] \"$ws_text[$sp[2]]\"
        ws-debug sp3=$sp[3] \"$ws_text[$sp[3]]\"
    fi
}

zle -N ws-testfun2
bindkey -M wskeys "^[\\\\" ws-testfun2
ws-testfun2() {
    wstext-del-sentence-right $CURSOR
    if [[ -n $wstext_pos ]]; then
        CURSOR=$wstext_pos
    fi
}

zle -N ws-start-doc
bindkey -M wskeys "^R" ws-start-doc
ws-start-doc() {
    CURSOR=0
}

zle -N ws-end-doc
bindkey -M wskeys "^C" ws-end-doc
ws-end-doc() {
    CURSOR=${#BUFFER}
}

bindkey -M wskeys "^Q^[" undefined-key
bindkey -M wskeys "^K^[" undefined-key
bindkey -M wskeys "^[" send-break

# Insert Keys
zle -N ws-self-insert
bindkey -M wskeys -R "!"-"~" ws-self-insert
bindkey -M wskeys " " ws-self-insert
ws-self-insert() {
    wstext-insert $CURSOR $KEYS
    CURSOR=$wstext_pos
}

zle -N ws-split-line
bindkey -M wskeys "^N" ws-split-line
ws-split-line() {
    wstext-insert $CURSOR \\$'\n'
    CURSOR=$wstext_pos
}

zle -N ws-kr
bindkey -M wskeys "^Kr" ws-kr
bindkey -M wskeys "^KR" ws-kr
ws-kr() {
    wsdialog_krdial-run
}

zle -N ws-bracketed-paste
bindkey -M wskeys "^[[200~" ws-bracketed-paste
ws-bracketed-paste() {
    local ws_pasted_text="$zle_bracketed_paste"
    zle bracketed-paste ws_pasted_text
    ws-debug pasted text is \"$ws_pasted_text\"
    wstext-insert $CURSOR $ws_pasted_text
    CURSOR=$wstext_pos
    #TODO: select (kb-kk), insert into kill ring...
}

# Delete keys: char
zle -N ws-del-char-left
bindkey -M wskeys "^H" ws-del-char-left
ws-del-char-left() {
    wstext-del-char-left $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-char-right
bindkey -M wskeys "^G" ws-del-char-right
ws-del-char-right() {
    wstext-del-char-right $CURSOR
    CURSOR=$wstext_pos
}

# Delete keys: word
zle -N ws-del-word-right
bindkey -M wskeys "^T" ws-del-word-right
ws-del-word-right() {
    wstext-del-word-right $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-word-left
bindkey -M wskeys "^[h" ws-del-word-left
bindkey -M wskeys "^[H" ws-del-word-left
ws-del-word-left() {
    wstext-del-word-left $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-word
bindkey -M wskeys "^[y" ws-del-word
bindkey -M wskeys "^[Y" ws-del-word
ws-del-word() {
    wstext-del-word $CURSOR
    CURSOR=$wstext_pos
}

# Delete keys: line
zle -N ws-del-line-left
bindkey -M wskeys "^Q^H" ws-del-line-left
ws-del-line-left() {
    wstext-del-line-left $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-line-right
bindkey -M wskeys "^Qy" ws-del-line-right
bindkey -M wskeys "^QY" ws-del-line-right
ws-del-line-right() {
    wstext-del-line-right $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-line
bindkey -M wskeys "^Y" ws-del-line
ws-del-line() {
    wstext-del-line $CURSOR
    CURSOR=$wstext_pos
}

# Delete keys: sentence
zle -N ws-del-sentence-left
bindkey -M wskeys "^Oh" ws-del-sentence-left
bindkey -M wskeys "^OH" ws-del-sentence-left
ws-del-sentence-left() {
    wstext-del-sentence-left $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-sentence-right
bindkey -M wskeys "^Og" ws-del-sentence-right
bindkey -M wskeys "^OG" ws-del-sentence-right
ws-del-sentence-right() {
    wstext-del-sentence-right $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-sentence
bindkey -M wskeys "^Oy" ws-del-sentence
bindkey -M wskeys "^OY" ws-del-sentence
ws-del-sentence() {
    wstext-del-sentence $CURSOR
    CURSOR=$wstext_pos
}

# Delete keys: paragraph
zle -N ws-del-paragraph-left
bindkey -M wskeys "^O^H" ws-del-paragraph-left
ws-del-paragraph-left() {
    wstext-del-paragraph-left $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-paragraph-right
bindkey -M wskeys "^O^G" ws-del-paragraph-right
ws-del-paragraph-right() {
    wstext-del-paragraph-right $CURSOR
    CURSOR=$wstext_pos
}

zle -N ws-del-paragraph
bindkey -M wskeys "^O^Y" ws-del-paragraph
ws-del-paragraph() {
    wstext-del-paragraph $CURSOR
    CURSOR=$wstext_pos
}


# Block Keys
#zle -N ws-kb
#bindkey -M wskeys "^Kb" ws-kb
#bindkey -M wskeys "^KB" ws-kb

zle -N ws-insert-saved
bindkey -M wskeys "^Kc" ws-insert-saved
bindkey -M wskeys "^KC" ws-insert-saved
bindkey -M wskeys "^Kv" ws-insert-saved
bindkey -M wskeys "^KV" ws-insert-saved
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
bindkey -M wskeys "^U" undo
bindkey -M wskeys "^6" redo

# Other Keys
bindkey -M wskeys "^M" accept-line
bindkey -M wskeys "^J" run-help
bindkey -M wskeys "^V" overwrite-mode
bindkey -M wskeys "^I" expand-or-complete

bindkey -M wskeys "^Ql" wskwtest
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
