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
    zle -K zsh-ws
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

#########other(shared)-function(s)/variables#########
ws_echo=$(sh -c 'which echo')

ws-do-bold() {
    i=$(( ${#region_highlight} + 1 ))
    base=$1
    y=0
    shift
    for x in $@
    do
        if [[ $y -eq 0 ]]; then
            v1=$(( $base + $x ))
            y=1
        else
            v2=$(( $base + $x ))
            y=0
	    region_highlight[$i]=("$v1 $v2 bold")
	    i=$(( $i + 1 ))
        fi
    done
}

ws-pos() {
    local from
    local to
    if [[ -n $1 ]]; then
        from=$(( $1 + 1 ))
    else
        from=1
    fi
    if [[ -n $2 ]]; then
        to=$(( $2 + 1 ))
    else
        to=$(( ${#BUFFER} + 1 ))
    fi
    local curs=$(( $CURSOR + 1 ))
    if [[ $from -le $curs && $curs -le $to ]]; then
        ws_row=1
        ws_col=1
        for i in {$from..$to}; do
            if [[ $i -eq $curs ]]; then
                break
            fi
            if [[ $BUFFER[$i] == $'\n' ]]; then
                ws_row=$(( $ws_row + 1 ))
                ws_col=1
            elif [[ $BUFFER[$i] == $'\t' ]]; then
                local rest=$(( ($ws_col - 1) % 8 ))
                ws_col=$(( $ws_col + 8 - $rest))
            elif [[ -n $kb && -z $kk && $i -eq $(( $kb + 1 )) ]]; then
                ws_col=$(( $ws_col - 2 ))                
            else
                ws_col=$(( $ws_col + 1 ))
            fi
        done
    fi
}

zle -N ws-print-pos
bindkey -M zsh-ws "^P" ws-print-pos
ws-print-pos() {
    if [[ -z $firstcurs ]]; then
        firstcurs=$CURSOR
        ws-pos $firstcurs
    else
        ws-pos $firstcurs
    fi
}


# testing dialog
wsdialog_modes[1]="dialogtest"

wsdialog_dialogtest_msg="Test dialog: "
wsdialog_dialogtest_modes[1]="diall4a"
wsdialog_dialogtest_modes[2]="secondl4"
wsdialog_dialogtest_accept="wsdialog-dialogtest-accept"
wsdialog_dialogtest_restore="wsdialog-dialogtest-restore"

wsdialog_dialogtest_diall4a_msg="#The string is short!# *Type* something... "
wsdialog_dialogtest_diall4a_accept="wsdialog-l4a-accept"

wsdialog_dialogtest_secondl4_msg="The string should not be #empty#..."
declare -A wsdialog_dialogtest_secondl4_funcs
wsdialog_dialogtest_secondl4_funcs["y"]="wsdialog-l4b-yes"
wsdialog_dialogtest_secondl4_funcs["Y"]="wsdialog-l4b-yes"
wsdialog_dialogtest_secondl4_funcs["n"]="wsdialog-l4b-no"
wsdialog_dialogtest_secondl4_funcs["N"]="wsdialog-l4b-no"
wsdialog_dialogtest_secondl4_funcs["^M"]="wsdialog-l4b-cm"

wsdialog-prepare

# decide based on $wsdialog_text what to do
wsdialog-dialogtest-accept() {
    if [[ -z $wsdialog_text ]]; then
        wsdialog_l4mode=secondl4_msg
    elif [[ ${#wsdialog_text} -lt 3 ]]; then
        wsdialog_l4mode=diall4a
    else
        undef wsdialog_l4mode
        zle -M "dialogtest: accept: \"$wsdialog_text\""
    fi
}

wsdialog-dialogtest-restore() {
    CURSOR=0
}

wsdialog-l4a-accept() {
    zle -M "dialogtest (a): l4-ok"
}

wsdialog-l4b-yes() {
    zle -M "dialogtest (b): yes"
}

wsdialog-l4b-no() {
    zle -M "dialogtest (b): no"
}

wsdialog-l4b-cm() {
    zle -M "dialogtest (b): ok"
}

bindkey -M zsh-ws "^Ql" test-wsdialog
zle -N test-wsdialog

test-wsdialog() {
    wsdialog_dialogtest_msg="msg is: "		
    wsdialog-dialogtest-run
}

bindkey -M zsh-ws "^Qm" test-format
zle -N test-format
test-format() {
    wsdialog-parse-format $BUFFER
    local fmt_string=""
    BUFFER=$wsdialog_pft
    CURSOR=${#wsdialog_pft}

    for fmt in $wsdialog_pff; do
        fmt_string+="[$fmt]"
    done

    region_highlight=""
    local fmts=($wsdialog_pff)
    for fmt in $fmts; do
	region_highlight+=($fmt)
    done

    zle -M "text=$wsdialog_pft format=$fmt_string"
}
