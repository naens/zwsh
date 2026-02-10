# HISTORY AND FIND FUNCTIONS
# ==========================
# ^QR=start-doc: start history
# ^QC=end-doc: end history
# ^W=up history using BUFFER contents (without search)
# ^C=down history using BUFFER contents (without search)
# ^L=repeat previous incremental search

zle -N ws-find
bindkey -M wskeys "^Qf" ws-find
bindkey -M wskeys "^QF" ws-find
ws-find() {
    ws_search=$LBUFFER
    hst=$HISTNO
    zle history-incremental-search-backward $ws_search
}

# FUTURE: find within block selection

bindkey -M isearch -R "!"-"~" self-insert
bindkey -M isearch " " self-insert

zle -N zle-history-line-set
zle-history-line-set() {
    wsblock-undef
    ws_text="$BUFFER"
}

# main mode find keys
bindkey -M wskeys "^Qr" beginning-of-buffer-or-history
bindkey -M wskeys "^QR" beginning-of-buffer-or-history
bindkey -M wskeys "^Qc" end-of-buffer-or-history
bindkey -M wskeys "^QC" end-of-buffer-or-history
bindkey -M wskeys "^W" history-search-backward
bindkey -M wskeys "^Z" history-search-forward

bindkey -M isearch "^H" backward-delete-char
bindkey -M isearch "^?" backward-delete-char

bindkey -M isearch "^E" history-incremental-search-backward
bindkey -M isearch "^L" history-incremental-search-backward
bindkey -M isearch "^X" history-incremental-search-forward

# repeat previous search
zle -N wsfind-repeat
bindkey -M wskeys "^L" wsfind-repeat
wsfind-repeat() {
    if [[ -n $ws_search ]]; then
        zle history-incremental-search-backward $ws_search
    fi
}

# undefine variables on isearch exit
zle -N zle-isearch-exit
zle-isearch-exit() {
    if [[ "$hst" != "$HISTNO" ]]; then
        unset kb
        unset kk
        unset region_highlight
    elif [[ -n $pre_rh ]]; then
        region_highlight="$pre_rh"
    fi
    unset hst
}


# default zsh search functions:
#accept-line-and-down-history
#expand-history
#infer-next-history
#
#down-line-or-beginning-search
#up-line-or-beginning-search
#
#down-line-or-history
#up-line-or-history
#
#  history-incremental-search-backward [^R]
#  history-incremental-search-forward  [^S]
#
#  beginning-of-buffer-or-history [alt.<]
#  end-of-buffer-or-history       [alt.>]
#  history-search-backward [alt.n]
#  history-search-forward  [alt.p]
