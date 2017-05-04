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
bindkey -M zsh-ws "^A" backward-word
bindkey -M zsh-ws "^F" forward-word

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
    ws-krfn
    wskr_insert="wskr-insert"
}
wskr-insert() {
    LBUFFER+=$wskr_text
    unset wskr_text
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
bindkey -M zsh-ws "^Qg" kill-line
bindkey -M zsh-ws "^QG" kill-line
bindkey -M zsh-ws "^Qh" backward-kill-line
bindkey -M zsh-ws "^QH" backward-kill-line

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
zle -N ws-kb
bindkey -M zsh-ws "^Kb" ws-kb
bindkey -M zsh-ws "^KB" ws-kb

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
debugfile=/dev/pts/1
if [[ ! -e $debugfile ]]; then
    debugfile=/dev/null
fi

# dialog
wsdialog_dialogtest_msg="Test dialog: "
wsdialog_dialogtest_modes[1]="l4empty"
wsdialog_dialogtest_modes[2]="l4short"
wsdialog_dialogtest_accept="wsdialog_dialogtest-accept"
wsdialog_dialogtest_restore="wsdialog_dialogtest-restore"

# l4short
wsdialog_dialogtest_l4short_msg="#The string is short!# Accept anyway? *Y*es *N*o *E*dit"
wsdialog_dialogtest_empty_msg="The string should not be #empty#..."
declare -A wsdialog_dialogtest_l4short_funcs
# y=accept short value; n=cancel, close dialog; e=continue editing (same as ^U)
wsdialog_dialogtest_l4short_funcs["y"]="l4short-yes"
wsdialog_dialogtest_l4short_funcs["Y"]="l4short-yes"
wsdialog_dialogtest_l4short_funcs["n"]="l4short-no"
wsdialog_dialogtest_l4short_funcs["N"]="l4short-no"
wsdialog_dialogtest_l4short_funcs["e"]="l4short-edit"
wsdialog_dialogtest_l4short_funcs["E"]="l4short-edit"


# l4empty (only show message, without other functionality)
wsdialog_dialogtest_l4empty_msg="The string should not be #empty#..."

# add dialog
wsdialog-add dialogtest

# decide whether display l4 or exit based on $wsdialog_text
wsdialog_dialogtest-accept() {
    if [[ -z $wsdialog_text ]]; then
        wsdialog_l4mode=l4empty
    elif [[ ${#wsdialog_text} -lt 4 ]]; then
        wsdialog_l4mode=l4short
    else
        unset wsdialog_l4mode
    fi
}

# function executed on return from dialog, $wsdialog_text holding the result
wsdialog_dialogtest-restore() {
    if [[ -n $wsdialog_text ]]; then
        zle -M "dialogtest: accept: \"$wsdialog_text\""
    else
        zle -M "dialogtext: no text in dialog"
    fi
}

l4short-yes() {
    echo YES > $debugfile
    zle -M "dialogtest (short): yes"
}

l4short-no() {
    zle -M "dialogtest (short): no"
}

l4short-edit() {
    zle -M "dialogtest (short): edit"
}
bindkey -M zsh-ws "^Ql" test-wsdialog
zle -N test-wsdialog

test-wsdialog() {
    wsdialog_dialogtest_msg="msg is: "		
    wsdialog_dialogtest-run
}
