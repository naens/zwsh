bindkey -N wsedit wskeys

#wsedit-pre-redraw() {
#    if [[ $CURSOR -le $wsedit_begin ]]; then
#        CURSOR=$wsedit_begin
#    fi
#    wsedit-refresh
#}

# Cursor Movement Functions
zle -N wsedit-prev-line
bindkey -M wsedit "^E" wsedit-prev-line
wsedit-prev-line() {
    if [[ $wsedit_row -gt 1 ]]; then
        wstext-jump-lines -1 $wsedit_tlines
    fi
}

zle -N wsedit-next-line
bindkey -M wsedit "^X" wsedit-next-line
wsedit-next-line() {
    wstext-jump-lines 1 $wsedit_tlines
}

zle -N wsedit-prev-screen
bindkey -M wsedit "^R" wsedit-prev-screen
wsedit-prev-screen() {
    if [[ $wsedit_row -lt $wsedit_slines ]]; then
        wstext-start-document
    elif [[ $wsedit_row -lt $((1.5*wsedit_slines)) ]]; then
        wsedit_yscroll=0
        wstext-jump-lines $((1-wsedit_slines)) $wsedit_tlines true
    else
        wsedit_yscroll=$((wsedit_yscroll-wsedit_slines))
        wstext-jump-lines $((-wsedit_slines)) $wsedit_tlines true
    fi
}

zle -N wsedit-next-screen
bindkey -M wsedit "^C" wsedit-next-screen
wsedit-next-screen() {
#    ws-debug WSEDIT_NEXT_SCREEN row=$wsedit_row tlines=$wsedit_tlines \
#                                slines=$wsedit_slines yscroll=$wsedit_yscroll
    if [[ $wsedit_tlines -gt $((wsedit_row+wsedit_slines)) ]]; then
        wsedit_yscroll=$((wsedit_yscroll+wsedit_slines))
        wstext-jump-lines $wsedit_slines $wsedit_tlines true
    elif [[ $wsedit_tlines -gt $wsedit_slines ]]; then
        wsedit_yscroll=$((wsedit_yscroll+wsedit_tlines-wsedit_row))
        wstext-jump-lines $((wsedit_tlines-wsedit_row)) $wsedit_tlines true
    else
        wstext-jump-lines $((wsedit_tlines-wsedit_row)) $wsedit_tlines true
    fi
}

zle -N wsedit-start-document
bindkey -M wsedit "^Qr" wsedit-start-document
bindkey -M wsedit "^QR" wsedit-start-document
wsedit-start-document() {
    wstext-start-document
}

zle -N wsedit-end-document
bindkey -M wsedit "^Qc" wsedit-end-document
bindkey -M wsedit "^QC" wsedit-end-document
wsedit-end-document() {
    # if tlines > yscroll + hscreen: yscroll := htext - (hscreen / 2)
    if [[ $wsedit_tlines -gt $((wsedit_yscroll + wsedit_slines)) ]]; then
        wsedit_yscroll=$((wsedit_tlines-wsedit_slines/2))
    fi
    wstext-end-document
}

# Cursor Scroll Functions TODO: ^ W/^Z (scroll line)
zle -N wsedit-scroll-up
bindkey -M wsedit "^W" wsedit-scroll-up
wsedit-scroll-up() {
    if [[ $wsedit_yscroll -gt 0 ]]; then
        wsedit_yscroll=$((wsedit_yscroll-1))
    fi

    if [[ $((wsedit_yscroll+wsedit_slines-1)) -lt $wsedit_row ]]; then
        wstext-jump-lines -1 $wsedit_tlines
    else
        wsedit-refresh
    fi
}

zle -N wsedit-scroll-down
bindkey -M wsedit "^Z" wsedit-scroll-down
wsedit-scroll-down() {
    # maxyscroll=tlines-1 [only last line is visible]
    if [[ $wsedit_yscroll -lt $((wsedit_tlines-1)) ]]; then
        wsedit_yscroll=$((wsedit_yscroll+1))
    fi

    if [[ $wsedit_yscroll -ge $wsedit_row ]]; then
        wstext-jump-lines 1 $wsedit_tlines
    else
        wsedit-refresh
    fi
}

# Cursor Screen Functions TODO: ^QE/^QX (begin/end screen)
zle -N wsedit-begin-screen
bindkey -M wsedit "^Qe" wsedit-begin-screen
bindkey -M wsedit "^QE" wsedit-begin-screen
wsedit-begin-screen() {
    wstext-jump-lines $((wsedit_yscroll-wsedit_row+1)) $wsedit_tlines true
}

zle -N wsedit-end-screen
bindkey -M wsedit "^Qx" wsedit-end-screen
bindkey -M wsedit "^QX" wsedit-end-screen
wsedit-end-screen() {
    local row=$((wsedit_yscroll+wsedit_slines-1))
    if [[ $row -ge $wsedit_tlines ]]; then
        row=$wsedit_tlines
    fi

    wsedit_pos=$(wstxtfun-line-last-pos $row "$wsedit_text" ${#wsedit_text})
    wsedit-refresh
}

# Insert Keys
zle -N wsedit-newline
bindkey -M wsedit "^M" wsedit-newline
wsedit-newline() {
    wstext-insert $'\n'
}

zle -N wsedit-splitline
bindkey -M wsedit "^N" wsedit-splitline
wsedit-splitline() {
    wstext-insert $'\n'
    wsedit_pos=$((wsedit_pos-1))
    wsedit-refresh
}

zle -N wsedit-tab
bindkey -M wsedit "^I" wsedit-tab
wsedit-tab() {
    wstext-insert $'\t'
}

declare -A wsedit_marks

# Switch main to editor mode key bindings
# Switch to editor mode: ^KD
zle -N ws-edit
bindkey -M wskeys "^Kd" ws-edit
bindkey -M wskeys "^KD" ws-edit
ws-edit() {
    wsedit_saved_keymap=$KEYMAP
    wsedit_begin=0     # no header yet

    # don't know if it can be changed, if so, must be replaced
    wsedit_tabwidth=8

    wsedit_fullscreen=false
    zle -K wsedit

    # save previous vars
    wstext_textvar_save=$wstext_textvar
    wstext_updfnvar_save=$wstext_updfnvar
    wstext_posvar_save=$wstext_posvar
    wstext_marksvar_save=$wstext_marksvar
    wstext_blockvisvar_save=$wstext_blockvisvar
    ws-debug wstext_blockvisvar=$wstext_blockvisvar
    wstext_blockcolmodevar_save=$wstext_blockcolmodevar

    # copy values from previous mode
    wsedit_text="${(P)wstext_textvar}"
    wsedit_pos=${(P)wstext_posvar}
    wsedit_marks=(${(Pkv)wstext_marksvar})
    wsedit_blockvis=${(P)wstext_blockvisvar}
    wsedit_blockcolmode=${(P)wstext_blockcolmodevar}

    # define 'var' variables
    wstext_textvar=wsedit_text
    wstext_updfnvar=wsedit-refresh
    wstext_posvar=wsedit_pos
    wstext_marksvar=wsedit_marks
    wstext_blockvisvar=wsedit_blockvis
    wstext_blockcolmodevar=wsedit_blockcolmode

    wsedit-refresh
}

# converts display position to position in string
dpos2spos() {
    local pos=$1
    local text="$2"
    local text_len=${#text}
    if [[ $pos -le $text_len ]]; then
        i=0 # count display characters
        j=0 # count string characters
        while [[ $i -lt $pos ]]; do
            if [[ "$text[j]" = $'\t' ]]; then
                i=$((i+8-i%8))
            elif [[ ! "$text[j]" = $'\n' ]]; then
                i=$((i+1))
            fi
            j=$((j+1))
        done
        echo $i
    fi
}

line_highlight() {
    local lnchr=$1    #character with which the line begins
    local text="$2"
    local nline=$3    #line number in same point of view as row variables
    local width=$4
    local xscroll=$5
    local brow=$6
    local bcol=$7
    local bscol=$(dpos2spos $bcol "$text")
    local krow=$8
    local kcol=$9
    local kscol=$(dpos2spos $kcol "$text")
    local colmode=${10}
    ws-debug WSEDIT_LINE_HIGHLIGHT: lnchr=$lnchr text=$text
    ws-debug WSEDIT_LINE_HIGHLIGHT: nline=$nline width=$width \
                                    colmode=$colmode xscroll=$xscroll
    ws-debug WSEDIT_LINE_HIGHLIGHT: brow=$brow bcol=$bcol bscol=$bscol \
                                    krow=$krow kcol=$kcol kscol=$kscol

    # testing highlight for minimal case: primitive column mode
    if [[ $xscroll -eq 0 && -n "$bcol" && -n "$kcol" \
          && $bcol -lt $kcol && $nline -ge $brow && $nline -le $krow ]]; then
        echo "$((lnchr+bscol-1)) $((lnchr+kscol-1)) standout"
    fi
}

# Refresh functions: modify buffer variable
# * make header
# * make part
# * make full

wsedit-mkhdr() {
    local ostr="Insert"
    if [[ $ZLE_STATE == *overwrite* ]]; then
        ostr=""
    fi
    local fn="<FILENAME>"
    if [[ -n "$wsedit_fn" ]]; then
        fn="$wsedit_fn"
    fi
    local header_text=$(printf "\n%16s       L%05d  C%03d %s fullscreens=%s" \
                               $fn $wsedit_row $wsedit_col $ostr $wsedit_fullscreen)
    wsedit_begin=$(( ${#header_text} + 2 ))
    BUFFER="$header_text"
}


wsedit-marks-order() {
    local b_pos=${wsedit_marks[B]}
    local k_pos=${wsedit_marks[K]}

    if [[ -n "$b_pos" && -n "$k_pos" ]]; then
        if [[ $b_pos -eq $k_pos ]]; then
            echo B K
        elif [[ $b_pos -lt $k_pos ]]; then
            echo B K +
        else
            echo K B
        fi
    elif [[ -n "$b_pos" ]]; then
        echo B
    elif [[ -n "$k_pos" ]]; then
        echo K
    fi
}

wsedit-mkprt() {
    local marks=($(wsedit-marks-order))

    if [[ ${#marks} -eq 3 ]]; then
        local from=$((wsedit_begin+wsedit_marks[B]-1))
        local to=$((wsedit_begin+wsedit_marks[K]-1))
        BUFFER+=$'\n'"$wsedit_text"
        CURSOR=$((wsedit_begin+wsedit_pos-1))
        region_highlight=("$from $to standout")
    else
        local i=1
        local pos=0
        local buf=""
        local reg=()
        local sft=$wsedit_begin
        local csft=$wsedit_begin
        while [[ $i -le ${#marks} ]]; do
            local next_letter=${marks[i]}
            local next_break=$wsedit_marks[$next_letter]
            buf+=$wsedit_text[pos,next_break]"<"$next_letter">"
            reg+=("$((sft+next_break-1)) $((sft+next_break+3-1)) standout")
            sft=$((sft+3))
            if [[ $wsedit_pos -ge $next_break ]]; then
                csft=$((csft+3))
            fi
            pos=$((next_break+1))
            i=$((i+1))
        done
        buf+=$wsedit_text[pos,${#wsedit_text}]
        region_highlight=($reg)
        BUFFER+=$'\n'"$buf"
        CURSOR=$((csft+wsedit_pos-1))
    fi
}

wsedit-mkful() {
    ws-debug WSEDIT_MKFUL: row=$wsedit_row col=$wsedit_col \
                           slines=$wsedit_slines scols=$wsedit_scols \
                           tlines=$wsedit_tlines


    ## define wsedit variables ##

    # wsblock variables #
    local b_pos=${wsedit_marks[B]}
    local k_pos=${wsedit_marks[K]}
    # $wsedit_blockvis: defined if block visible
    # $wsedit_blockcolmode: defined if column mode
    ws-debug WSEDIT_REFRESH b_pos=$b_pos k_pos=$k_pos \
            vis=$wsedit_blockvis col=$wsedit_blockcolmode
    if [[ -n "$b_pos" ]]; then
        read wsedit_brow wsedit_bcol <<< $(wstxtfun-pos $b_pos "$wsedit_text")
        local bp=$(wstxtfun-line-start $b_pos "$wsedit_text")
        wsedit_bcol=$(wstxtfun-real-col $wsedit_bcol $wsedit_tabwidth \
        		 "$wsedit_text[$bp,${#wsedit_text}]")
    else
        unset wsedit_brow
        unset wsedit_bcol
    fi
    if [[ -n "$k_pos" ]]; then
        read wsedit_krow wsedit_kcol <<< $(wstxtfun-pos $k_pos "$wsedit_text")
        local kp=$(wstxtfun-line-start $kpos "$wsedit_text")
        wsedit_kcol=$(wstxtfun-real-col $wsedit_kcol $wsedit_tabwidth \
        		 "$wsedit_text[$kp,${#wsedit_text}]")
    else
        unset wsedit_krow
        unset wsedit_kcol
    fi
 
    # TODO: convert bcol and kcol to columns on display (expand tabs)

    ws-debug WSEDIT_MKFUL: brow=$wsedit_brow bcol=$wsedit_bcol \
                           krow=$wsedit_krow kcol=$wsedit_kcol


    # wsedit scroll variables #
    if [[ -z "$wsedit_yscroll" ]]; then
        wsedit_yscroll=0
    fi
    if [[ $((wsedit_row-1)) -lt $wsedit_yscroll ]]; then
        wsedit_yscroll=$((wsedit_row-1))
    elif [[ $((wsedit_row)) -ge $((wsedit_yscroll+wsedit_slines-1)) ]]; then
        wsedit_yscroll=$((wsedit_row-wsedit_slines+1))
    fi

    local step=$((wsedit_scols<20?1:wsedit_scols<40?5:wsedit_scols<60?10:20))
    if [[ -z "$wsedit_xscroll" ]]; then
        wsedit_xscroll=0
    fi
    local p=$((wsedit_col-1))

    if [[ $p -lt $wsedit_xscroll ]]; then
        wsedit_xscroll=$(( (p-1)-(p-1)%step ))
    elif [[ $p -gt $((wsedit_xscroll+wsedit_scols-2)) ]]; then
        wsedit_xscroll=$(( (p-wsedit_scols+1)-(p-wsedit_scols+1)%step+step ))
    fi

    ws-debug yscroll=$wsedit_yscroll xscroll=$wsedit_xscroll step=$step

    ## local variables ##
#    local prompt="$PROMPT"
#    PROMPT=''
#    zle reset-prompt

#    local buf=""
    local line_from=$((wsedit_yscroll+1))
    local line_to=$((line_from-1+$(ws-min $((wsedit_tlines-wsedit_yscroll)) \
                                              $((wsedit_slines-1)))))
#    local tlen=${#wsedit_text}
    
#    local i=$(wstxtfun-line2pos line_from "$wsedit_text")
#    local line_len=0
#    local line_counter=1

    local x_from=$wsedit_xscroll
    local x_to=$((x_from+wsedit_scols-1))
    local x=0
#    local lnchr=$wsedit_begin
#    local reg=()

    # TODO: by-line loop: line_from..line_to
    ws-debug WSEDIT_MKFUL: line_from=$line_from line_to=$line_to
    local curr_pos=$(wstxtfun-line2pos $line_from "$wsedit_text")
    local i=$line_from
    while [[ $i -le $line_to ]]; do
#        ws-debug WSEDIT_MKFUL: i=$i

        # get text line
        local i_text=""
        if [[ $i -lt $line_to ]]; then
            local next_pos=$(wstxtfun-line2pos $((i+1)) "$wsedit_text")
            i_text=$wsedit_text[curr_pos,next_pos-2]
#            ws-debug WSEDIT_MKFUL: i=$i curr_pos=$curr_pos next_pos=$next_pos
        else
            i_text=$wsedit_text[curr_pos,${#wsedit_text}]
#            ws-debug WSEDIT_MKFUL: last line: i=$i
        fi
        ws-debug WSEDIT_MKFUL: i=$i pos=$curr_pos i_text=\"$i_text\"

	# make line as it will be displayed

        curr_pos=$next_pos
        i=$((i+1))
    done

#    PROMPT="$prompt"
#        while true; do
#            local char=$wsedit_text[i]
#            if [[ $x -eq $x_to ]]; then
#                buf+="+"
#                line_len=0
#                x=-1
#                while [[ ! "$wsedit_text[i]" = $'\n' && $i -le $tlen ]]; do
#                    i=$((i+1))
#                done
#                if [[ $i -gt $tlen ]]; then
#                    break
#                else
#                    line_counter=$((line_counter+1))
#                fi
#            elif [[ "$char" = $'\n' || $i -gt $tlen ]]; then
#                if [[ -n "$wsedit_blockvis" ]]; then
#                    local r=$(line_highlight $lnchr "$wsedit_text[i-line_len,i]" \
#                            $((line_counter+line_from-1)) \
#                            $wsedit_scols $wsedit_xscroll \
#                           "$wsedit_brow" "$wsedit_bcol" \
#                           "$wsedit_krow" "$wsedit_kcol" \
#                           "$wsedit_blockcolmode")
#                    reg+=("$r")
#                    
#                fi
#                lnchr=$((lnchr+wsedit_scols))
#                if [[ $wsedit_scols -gt $line_len ]]; then
#                    for j in {1..$((wsedit_scols-line_len-1))}; do
#                        buf+=" "
#                    done
#                fi
#                if [[ $line_counter -le $((line_to-line_from)) ]]; then
#                    buf+="<"
#                elif [[ $((line_counter+wsedit_yscroll)) -eq $wsedit_tlines ]]; then
#                    buf+="^"
#                    break
#                else
#                    buf+="<"
#                    break
#                fi
#                line_len=0
#                x=-1
#                line_counter=$((line_counter+1))
#            elif [[ $x -ge $x_from && $x -lt $x_to ]]; then
#                buf+="$char"
#                line_len=$((line_len+1))
#            fi
#            i=$((i+1))
#            x=$((x+1))
#        done
#        i=1
#        local empty_lines=$((wsedit_slines-wsedit_tlines-1))
#        while [[ $i -le $empty_lines ]]; do
#            for j in {1..$((wsedit_scols-1))}; do
#                buf+="."
#            done
#            buf+="^"
#            i=$((i+1))
#        done
#        BUFFER+="$buf"
#        region_highlight=($reg)
#        # y and x on the text part of the screen
#        local curs_y=$(( wsedit_row - line_from ))
#        local curs_x=$(( wsedit_col - 1 - x_from ))
#        if [[ $curs_x -lt 0 ]]; then
#            curs_x=0
#        fi
#        if [[ $curs_x -gt $(( wsedit_scols - 1 )) ]]; then
#            curs_x=$(( wsedit_scols - 1 ))
#        fi
#
#        CURSOR=$(( wsedit_begin + wsedit_scols * curs_y + curs_x - 1 ))
#        PROMPT="$prompt"
}

# overwrite area between 0 and $wsedit_begin with an updated header
# update $wsedit_begin to match the next character after the header
# TODO: restructure function
# TODO: separate: make-header, make-partscreen, make-fullscreen
# TODO: restructure each function in manageable size
# TODO: fullscreen: allow tabs
wsedit-refresh() {
    read wsedit_row wsedit_col <<< $(wstxtfun-pos $wsedit_pos "$wsedit_text")

    wsedit_tlines=$(wstxtfun-nlines "$wsedit_text")

    region_highlight=()

    wsedit_slines=$(($(tput lines) - 1))
    wsedit_scols=$(($(tput cols)))

    if ! $wsedit_fullscreen && [[ $wsedit_tlines -ge $wsedit_slines ]]; then
        wsedit_fullscreen=true
    fi

    wsedit-mkhdr

    if $wsedit_fullscreen; then
        wsedit-mkful
    else
        wsedit-mkprt
    fi
    ws-debug WSEDIT_REFRESH: region_highlight="$region_highlight"
}

# Switch to *editor mode* and open a file: ^KE
# Switch to *editor mode* saving buffer as file: ^KS

# Switch /editor mode/ to main mode
# Exit *editor mode* (do not save), with file contents as buffer: ^KD
# TODO: in fullscreen mode, text can have more lines than the buffer
#       if text bigger, than the buffer, put the whole text in the buffer
#       if text smaller, remove supplementary lines from the buffer
#         => !!! cursor position
zle -N wsedit-exit
bindkey -M wsedit "^Kd" wsedit-exit
bindkey -M wsedit "^KD" wsedit-exit
wsedit-exit() {
    CURSOR=$((CURSOR-wsedit_begin))

    # restore previous variables
    wstext_textvar=$wstext_textvar_save
    wstext_updfnvar=$wstext_updfnvar_save
    wstext_posvar=$wstext_posvar_save
    wstext_marksvar=$wstext_marksvar_save
    wstext_blockvisvar=$wstext_blockvisvar_save
    wstext_blockcolmodevar=$wstext_blockcolmodevar_save

    ws-defvar $wstext_textvar "$wsedit_text"
    eval "$wstext_posvar=\"$wsedit_pos\""
    eval "$wstext_marksvar=(${(kv)wsedit_marks})"
    eval "$wstext_blockvisvar=$wsedit_blockvis"
    if [[ -n "$wstext_blockcolmodevar" ]]; then
        eval "$wstext_blockcolmodevar=$wsedit_blockcolmode"
    fi

    unset wsedit_begin
    unset wsedit_text
    unset wsedit_pos
    unset wsedit_marksvar_array
    unset wsedit_blockvis
    unset wsedit_blockcolmode
    zle -K $wsedit_saved_keymap
    $wstext_updfnvar
    zle reset-prompt
}

# Close the currenpt file and save: ^KX (buffer empty)
# Close the current file without saving: ^KQ (buffer empty)

# Enter fullscreen mode
zle -N wsedit-fullscreen
bindkey -M wsedit "^Kf" wsedit-fullscreen
bindkey -M wsedit "^KF" wsedit-fullscreen
wsedit-fullscreen() {
    # toggle fullscreen mode
    wsedit_fullscreen=$(not $wsedit_fullscreen)
    wsedit-refresh
}


# Block functions
#zle -N wseditblock-kb
#bindkey -M wsedit "^Kb" wseditblock-kb
#bindkey -M wsedit "^KB" wseditblock-kb

# TODO: * file import/export functions
# TODO: * dialog=new screen!!! => save-and-replace buffer
zle -N wsedit-kr
bindkey -M wsedit "^Kr" wsedit-kr
bindkey -M wsedit "^KR" wsedit-kr
wsedit-kr() {
    BUFFER=""
    wsdfopen_endfn=wsedit-kr-end
    wsdfopen-run
}

wsedit-kr-end() {
    wsedit_begin=0
    if [[ -n "$wsdfopen_text" ]]; then
        wstext-insert "$wsdfopen_text"
    fi
}

# open file
zle -N wsedit-open
bindkey -M wsedit "^Ke" wsedit-open
bindkey -M wsedit "^KE" wsedit-open
wsedit-open() {
    BUFFER=""
    wsdfopen_endfn=wsedit-open-end
    wsdfopen-run
}

wsedit-open-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfopen_fn"
        wsedit_text="$wsdfopen_text"

        wsedit_pos=0
    fi
}

# save file
zle -N wsedit-save
bindkey -M wsedit "^Ks" wsedit-save
bindkey -M wsedit "^KS" wsedit-save
wsedit-save() {
    if [[ -n "$wsedit_fn" ]]; then
        if $ws_echo "$wsedit_text" 2>&- > "$wsedit_fn"; then
            return
        fi
    fi
    BUFFER=""
    wsdfsave_text="$wsedit_text"
    wsdfsave_endfn=wsedit-save-end
    wsdfsave-run
}

wsedit-save-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfsave_fn"
    fi
}


# save file as
zle -N wsedit-save-as
bindkey -M wsedit "^Ko" wsedit-save-as
bindkey -M wsedit "^KO" wsedit-save-as
wsedit-save-as() {
    BUFFER=""
    wsdfsave_text="$wsedit_text"
    wsdfsave_endfn=wsedit-save-as-end
    wsdfsave-run
}

wsedit-save-as-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfsave_fn"
    fi
}


# save and close 
zle -N wsedit-save-exit
bindkey -M wsedit "^Kx" wsedit-save-exit
bindkey -M wsedit "^KX" wsedit-save-exit
wsedit-save-exit() {
    if [[ -n "$wsedit_fn" ]]; then
        if $ws_echo "$wsedit_text" 2>&- > "$wsedit_fn"; then
            wsedit-save-exit-end
            return
        fi
    fi
    BUFFER=""
    wsdfsave_text="$wsedit_text"
    wsdfsave_endfn=wsedit-save-exit-end
    wsdfsave-run
}

wsedit-save-exit-end() {
    wsedit_text=""
    wsedit-exit
}

# exit without saving.  TODO: ask if need saving
zle -N wsedit-quit
bindkey -M wsedit "^Kq" wsedit-quit
bindkey -M wsedit "^KQ" wsedit-quit
wsedit-quit() {
    wsedit_text=""
    wsedit-exit
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

wskeys-save-edit-end() {
    if [[ "$1" = "OK" ]]; then
        wsedit_fn="$wsdfsave_fn"
        ws-edit
    fi
}

# TODO: * Find functions
bindkey -M wsedit "^Qf" undefined-key
bindkey -M wsedit "^QF" undefined-key
bindkey -M wsedit "^L" undefined-key
