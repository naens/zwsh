# file contains all keybindings, calls function depending
# on the state

bindkey -N wskeys
bindkey -M wskeys -R " "-"~" self-insert

declare -A ws_marks

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
    unset ws_curs
    ws_marks=()
    unset ws_blockvis
    zle -K wskeys

    # name of the variable containing the text
    wstext_textvar=ws_text
    wstext_updfnvar=ws-updfn
    wstext_posvar=ws_curs
    wstext_marksvar=ws_marks
    wstext_blockvisvar=ws_blockvis
    unset wstext_blockcolmodevar

    ws_text="$BUFFER"
    ws_curs=$CURSOR
}

# History keys
bindkey -M wskeys "^E" up-line-or-history
bindkey -M wskeys "^X" down-line-or-history

# Cursor Move: character
zle -N ws-char-left
bindkey -M wskeys "^S" ws-char-left
ws-char-left() {
    wstext-char-left
}

zle -N ws-char-right
bindkey -M wskeys "^D" ws-char-right
ws-char-right() {
    wstext-char-right
}

# Cursor Move: word
zle -N ws-word-left
bindkey -M wskeys "^A" ws-word-left
ws-word-left() {
    wstext-prev-word
}

zle -N ws-word-right
bindkey -M wskeys "^F" ws-word-right
ws-word-right() {
    wstext-next-word
}

# Cursor move: line
zle -N ws-line-start
bindkey -M wskeys "^Qs" ws-line-start
bindkey -M wskeys "^QS" ws-line-start
ws-line-start() {
    wstext-line-start
}

zle -N ws-line-end
bindkey -M wskeys "^Qd" ws-line-end
bindkey -M wskeys "^QD" ws-line-end
ws-line-end() {
    wstext-line-end
}

# Cursor move: sentence
zle -N ws-prev-sentence
#bindkey -M wskeys "^Os" ws-prev-sentence
#bindkey -M wskeys "^OS" ws-prev-sentence
ws-prev-sentence() {
    wstext-prev-sentence
}

zle -N ws-next-sentence
#bindkey -M wskeys "^Od" ws-next-sentence
#bindkey -M wskeys "^OD" ws-next-sentence
ws-next-sentence() {
    wstext-next-sentence
}

# Cursor move: paragraph
zle -N ws-prev-paragraph
#bindkey -M wskeys "^O^S" ws-prev-paragraph
ws-prev-paragraph() {
    wstext-prev-paragraph
}

zle -N ws-next-paragraph
#bindkey -M wskeys "^O^D" ws-next-paragraph
ws-next-paragraph() {
    wstext-next-paragraph
}

#    if [[ -n $kk ]]; then
#        region_highlight=("$kb $kk standout")
#    else
#        region_highlight=("$kb $(( $kb + 3)) standout")
#    fi

# TODO: use marks for wsblock kb and kk!!!
ws-updfn() {
    local b_pos=${ws_marks[B]}
    local k_pos=${ws_marks[K]}
#    ws-debug WS_UPDFN: b_pos=$b_pos k_pos=$k_pos pos=$ws_curs \
#                       vis=$ws_blockvis text=\""$ws_text"\"

    if [[ -n "$ws_blockvis" ]]; then
        local text="$ws_text"
        local curs=$ws_curs
        if [[ -n "$b_pos" && -n "$k_pos" && $k_pos -gt $b_pos ]]; then
            region_highlight=("$b_pos $k_pos standout")
        elif [[ -n "$b_pos" && -z "$k_pos" ]]; then
            text=$text[1,b_pos]"<B>"$text[b_pos+1,${#text}]
            region_highlight=("$b_pos $((b_pos+3)) standout")
            if [[ $curs -ge $b_pos ]]; then
                curs=$((curs+3))
            fi
        elif [[ -n "$k_pos" && -z "$b_pos" ]]; then
            text=$text[1,k_pos]"<K>"$text[k_pos+1,${#text}]
            region_highlight=("$k_pos $((k_pos+3)) standout")
            if [[ $curs -ge $k_pos ]]; then
                curs=$((curs+3))
            fi
        elif [[ $b_pos -eq $k_pos ]]; then
            text=$text[1,b_pos]"<B><K>"$text[b_pos+1,${#text}]
            region_highlight=("$b_pos $((b_pos+6)) standout")
            if [[ $curs -ge $b_pos ]]; then
                curs=$((curs+6))
            fi
        else # b > k
            text=$text[1,k_pos]"<K>"$text[k_pos+1,b_pos]"<B>"$text[b_pos+1,${#text}]
            region_highlight=("$k_pos $((k_pos+3)) standout" \
                              "$((b_pos+3)) $((b_pos+6)) standout")
            if [[ $curs -lt $b_pos && $curs -ge $k_pos ]]; then
                curs=$((curs+3))
            elif [[ $curs -ge $b_pos && $curs -ge $k_pos ]]; then
                curs=$((curs+6))
            fi
        fi
        BUFFER="$text"
        CURSOR=$curs
    else
        region_highlight=()
        BUFFER="$ws_text"
        CURSOR=$ws_curs
   fi
#    ws-debug WS_UPDFN: pos=$ws_curs text=\""$ws_text"\"
}

#zle -N ws-start-doc
#bindkey -M wskeys "^R" ws-start-doc
#ws-start-doc() {
#    eval "$wstext_posvar=0"
#}

#zle -N ws-end-doc
#bindkey -M wskeys "^C" ws-end-doc
#ws-end-doc() {
#    local text="${(P)wstext_textvar}"
#    eval "$wstext_posvar=${#text}"
#}

bindkey -M wskeys "^Q^[" undefined-key
bindkey -M wskeys "^K^[" undefined-key
bindkey -M wskeys "^[" send-break

# Insert Keys
zle -N ws-self-insert
bindkey -M wskeys -R "!"-"~" ws-self-insert
bindkey -M wskeys " " ws-self-insert
ws-self-insert() {
    wstext-insert "$KEYS"
}

zle -N ws-split-line
bindkey -M wskeys "^N" ws-split-line
ws-split-line() {
    wstext-insert $'\n'
    wstext-char-left
    ws-edit
}

zle -N ws-kr
bindkey -M wskeys "^Kr" ws-kr
bindkey -M wskeys "^KR" ws-kr
ws-kr() {
    wsdfopen_endfn=ws-kr-end
    wsdfopen-run
}

ws-kr-end() {
    if [[ -n "$wsdfopen_text" ]]; then
        wstext-insert "$wsdfopen_text"
    fi
}

# save buffer contents and enter edit mode
zle -N wskeys-save-edit
bindkey -M wskeys "^Ks" wskeys-save-edit
bindkey -M wskeys "^KS" wskeys-save-edit
wskeys-save-edit() {
    wsdfsave_text="$ws_text"
    wsdfsave_endfn=wskeys-save-edit-end
    wsdfsave-run
}

zle -N ws-kx
bindkey -M wskeys "^Kx" ws-kx
bindkey -M wskeys "^KX" ws-kx
ws-kx() {
    wsdfsave_text="$ws_text"
    wsdfsave-run
}

zle -N wskeys-exit
bindkey -M wskeys "^Kq" wskeys-exit
bindkey -M wskeys "^KQ" wskeys-exit
wskeys-exit() {
    if [[ ${#BUFFER} -gt 0 ]]; then
        wsdquit-run wskeys-exit-yes wskeys-exit-no
    else
        wskeys-exit-yes
    fi
}

wskeys-exit-yes() {
    exit
}

wskeys-exit-no() {
}

zle -N ws-bracketed-paste
bindkey -M wskeys "^[[200~" ws-bracketed-paste
ws-bracketed-paste() {
    local ws_pasted_text="$zle_bracketed_paste"
    zle bracketed-paste ws_pasted_text
    wstext-insert $ws_pasted_text
    #TODO: select (kb-kk), insert into kill ring...
}

# Delete keys: char
zle -N ws-del-char-left
bindkey -M wskeys "^?" ws-del-char-left
bindkey -M wskeys "^H" ws-del-char-left
ws-del-char-left() {
    wstext-del-char-left
}

zle -N ws-del-char-right
bindkey -M wskeys "^G" ws-del-char-right
ws-del-char-right() {
    wstext-del-char-right
}

# Delete keys: word
zle -N ws-del-word-right
bindkey -M wskeys "^T" ws-del-word-right
ws-del-word-right() {
    wstext-del-word-right
}

zle -N ws-del-word-left
#bindkey -M wskeys "^[h" ws-del-word-left
#bindkey -M wskeys "^[H" ws-del-word-left
ws-del-word-left() {
    wstext-del-word-left
}

zle -N ws-del-word
#bindkey -M wskeys "^[y" ws-del-word
#bindkey -M wskeys "^[Y" ws-del-word
ws-del-word() {
    wstext-del-word
}

# Delete keys: line
zle -N ws-del-line-left
bindkey -M wskeys "^Q^H" ws-del-line-left
ws-del-line-left() {
    wstext-del-line-left
}

zle -N ws-del-line-right
bindkey -M wskeys "^Qy" ws-del-line-right
bindkey -M wskeys "^QY" ws-del-line-right
ws-del-line-right() {
    wstext-del-line-right
}

zle -N ws-del-line
bindkey -M wskeys "^Y" ws-del-line
ws-del-line() {
    wstext-del-line
}

# Delete keys: sentence
zle -N ws-del-sentence-left
#bindkey -M wskeys "^Oh" ws-del-sentence-left
#bindkey -M wskeys "^OH" ws-del-sentence-left
ws-del-sentence-left() {
    wstext-del-sentence-left
}

zle -N ws-del-sentence-right
#bindkey -M wskeys "^Og" ws-del-sentence-right
#bindkey -M wskeys "^OG" ws-del-sentence-right
ws-del-sentence-right() {
    wstext-del-sentence-right
}

zle -N ws-del-sentence
#bindkey -M wskeys "^Oy" ws-del-sentence
#bindkey -M wskeys "^OY" ws-del-sentence
ws-del-sentence() {
    wstext-del-sentence
}

# Delete keys: paragraph
zle -N ws-del-paragraph-left
#bindkey -M wskeys "^O^H" ws-del-paragraph-left
ws-del-paragraph-left() {
    wstext-del-paragraph-left
}

zle -N ws-del-paragraph-right
#bindkey -M wskeys "^O^G" ws-del-paragraph-right
ws-del-paragraph-right() {
    wstext-del-paragraph-right
}

zle -N ws-del-paragraph
#bindkey -M wskeys "^O^Y" ws-del-paragraph
ws-del-paragraph() {
    wstext-del-paragraph
}


zle -N ws-insert-saved
bindkey -M wskeys "^Kc" ws-insert-saved
bindkey -M wskeys "^KC" ws-insert-saved
bindkey -M wskeys "^Kv" ws-insert-saved
bindkey -M wskeys "^KV" ws-insert-saved
# on ^Kc/^Kv insert saved substring if exists and nothing selected
ws-insert-saved() {
#    if [[ -n $ws_saved ]]; then
#    kb=$CURSOR
#    kk=$(( $CURSOR + ${#ws_saved} ))
#    LBUFFER+=$ws_saved
#    CURSOR=$(( $CURSOR + ${#ws_saved} ))
#    zle -K wsblock
#    wsblock-upd
#    fi
}

# Undo Keys
bindkey -M wskeys "^_" undo
bindkey -M wskeys "^6" redo

zle -N wskeys-unerase
bindkey -M wskeys "^U" wskeys-unerase
wskeys-unerase() {
    if [[ -n "$ws_delbuf" ]]; then
        wstext-insert "$ws_delbuf"
        if [[ $(wstxtfun-nlines "$ws_delbuf") -gt 1 ]]; then
            wsedit-mode
        fi
    fi
}

## wskeys-ctrl: begin
bindkey -N wskeys-ctrl

zle -N wskeys-insert-ctrl-mode
bindkey -M wskeys "^P" wskeys-insert-ctrl-mode
wskeys-insert-ctrl-mode() {
    wskeys_ctrl_saved_keymap=$KEYMAP
    zle -K wskeys-ctrl
}

zle -N wskeys-ctrl-insert
bindkey -M wskeys-ctrl -R "^@"-"\M-^?" wskeys-ctrl-insert
wskeys-ctrl-insert() {
    wstext-insert $KEYS
    zle -K $wskeys_ctrl_saved_keymap
}

#zle -N wskeys-ctrl-n
#bindkey -M wskeys-ctrl "^J" wskeys-ctrl-n
#wskeys-ctrl-n() {
#    zle -K $wskeys_ctrl_saved_keymap
#    ws-split-line
#}

zle -N wskeys-ctrl-exit
bindkey -M wskeys-ctrl "^\`" wskeys-ctrl-exit
wskeys-ctrl-exit() {
    zle -K $wskeys_ctrl_saved_keymap
}

## wskeys-ctrl: end


# Other Keys
zle -N wskeys-accept-line
#bindkey -M wskeys "^[^M" accept-line
bindkey -M wskeys "^[m" accept-line
bindkey -M wskeys "^M" wskeys-accept-line
wskeys-accept-line() {
    # substitute special folders:
    #  * if outside ' and " quotes (not quoted and not escaped)
    #  * if is not following alnum character, nor active $, nor active \
    #  * if is not commented (not following # on the same line)
    #  * is followed by :
    local in_sq=""
    local in_dq=""
    local var_act=""
    local bsl_act=""
    local in_wd=""
    local in_com=""
    local i=1
    local old_buffer="$BUFFER"
    local new_buffer=""
    while [[ $i -le ${#old_buffer} ]]; do
        local char=$old_buffer[$i]
        local found=""
        if [[ -z $in_sq && -z $in_dq && -z $var_act && -z $bsl_act
           && -z $in_wd && -z $in_com && "$char" =~ [[:alnum:]_-] ]]; then
            # if there is a substituable string beginning from $i, replace
            for k in ${(k)zw_special_folders}; do
                folder=$zw_special_folders[$k]
                local klen=${#k}
#                ws-debug i=$i len=${#old_buffer} k=$k klen=$klen folder=$folder ob=\""$old_buffer[i,i+klen]"\"
                if [[ $((i+klen)) -le ${#old_buffer}
                   && $(ws-uc "$old_buffer[i,i+klen]") = "$k:" ]]; then
                    found=1
#                    ws-debug FOUND $k:
                    new_buffer+="$folder/"
                    i=$((i+klen+1))
                    break
                fi
            done
            if [[ -n "$found" ]]; then
                continue
            fi
        fi

        # test single quote
        if [[ -z $in_sq && -z $in_dq && -z $bsl_act && -z $in_com && "$char" = "'" ]]; then
            in_sq=1
        elif [[ -n $in_sq && -z $in_dq && -z $bsl_act && -z $in_com && "$char" = "'" ]]; then
            in_sq=""
        fi

        # test $var
        if [[ -z $in_sq && -z $var_act && -z $bsl_act && -z $in_com && "$char" = "\$" ]]; then
            var_act=1
        elif [[ -z $in_sq && -n $var_act && -z $bsl_act && -z $in_com ]]; then
            var_act=""
        fi

        # test double quote
        if [[ -z $in_sq && -z $in_dq && -z $bsl_act && -z $in_com && "$char" = "\"" ]]; then
            in_dq=1
        elif [[ -z $in_sq && -n $in_dq && -z $bsl_act && -z $in_com && "$char" = "\"" ]]; then
            in_dq=""
        fi

        # test backslash
        if [[ -z $bsl_act && -z $in_com && "$char" = "\\" ]]; then
            bsl_act=1
        elif [[ -n $bsl_act ]]; then
            bsl_act=""
        fi

        # test in_wd
        if [[ -z $in_sq && -z $in_dq && -z $bsl_act
           && -z $in_wd && -z $in_com && "$char" =~ [[:alnum:]_-] ]]; then
            in_wd=1
        elif [[ -z $in_sq && -z $in_dq && -z $bsl_act
           && -n $in_wd && -z $in_com && ! "$char" =~ [[:alnum:]_-] ]]; then
            in_wd=""
        fi

        # test in_com
        if [[ -z $in_sq && -z $in_dq && -z $bsl_act && -z $in_com && "$char" = "#" ]]; then
            in_com=1
        elif [[ -n $in_com && "$char" = $'\n' ]]; then
            in_com=""
        fi

        new_buffer+="$char"
        i=$((i+1))
    done

    if [[ -d "$new_buffer" ]]; then # TODO: allow spaces before/after
        cd "$new_buffer"
        echo
        BUFFER=""
        zle reset-prompt
    else
#        print -s "$BUFFER"
#        zle down-history
#        echo
#        echo "$new_buffer" | source /dev/stdin # TODO: improve
#        eval "$new_buffer"
#        - "$new_buffer"

#        BUFFER=""
#        zle reset-prompt
#        zle execute-named-cmd "$new_buffer"

        BUFFER="$new_buffer"
        zle .accept-line

    fi
}

bindkey -M wskeys "^J" run-help
bindkey -M wskeys "^V" overwrite-mode
bindkey -M wskeys "^I" expand-or-complete

zle -N wskeys-exec-to-prompt
bindkey -M wskeys "^Km" wskeys-exec-to-prompt
bindkey -M wskeys "^KM" wskeys-exec-to-prompt
wskeys-exec-to-prompt() {
    local newbuf=$(eval $ws_text 2>&-)
    if [[ -n "$newbuf" ]]; then
        ws_text="$newbuf"
        ws_curs=0
        ws-updfn
    fi
}

# replace buffer with contents from file and enter edit mode
zle -N wskeys-replace
bindkey -M wskeys "^Ke" wskeys-replace
bindkey -M wskeys "^KE" wskeys-replace
wskeys-replace() {
    wsdialog-wsdfopen-run
    wsdfopen_endfn=wstext-replace-enter
}

wstext-replace-enter() {
    if [[ "$1" = "OK" ]]; then
        ws_text="$wsdfopen_text"

        wsedit_fn="$wsdfopen_fn"
        ws-edit
    else
        $wstext_updfnvar
    fi
}

wskeys-save-edit-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfsave_fn"
        ws-edit
    fi
}

zle -N zle-line-pre-redraw
zle-line-pre-redraw() {
    local modefun=$KEYMAP-pre-redraw
    if typeset -f $modefun > /dev/null; then
        $modefun
    fi
}

wskeys-pre-redraw() {
    # TODO: fix fix fix
    if [[ -z "$ws_blockvis" ]]; then
        ws_text="$BUFFER" # TODO: on tab expand: redefine ws_text
        ws_curs=$CURSOR
#        ws-updfn # temporary
    fi
}
