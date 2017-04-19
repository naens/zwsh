skip() {}

# prepare dialogs
wsdialog-prepare() {
    for dialog in wsdialog_modes; do
        local dname="wsdialog_"$dialog
        local dfn="wsdialog-"$dialog
        local mname=$dname"_line"
        bindkey -N $mname wsline
        zle -N $mname "^M" $dname"_accept"
        bindkey -M $mname "^M" $dname"_accept"
        zle -N $mname "^U" $dname"_restore"
        bindkey -M $mname "^U" $dname"_restore"
        local modesvar=$dname"_modes"
        local modes=$(eval echo \$$modesvar)
        for l4mode in $modes; do
            local l4mname=$l4mode"_l4"
            bindkey -N $l4mname
            zle -N $l4mname "^U" "${dfn}-rml4"
            bindkey -M $l4mname "^U" "${dfn}-rml4"
        done
        eval ${dfn}-run() { wsdialog-run $dialog }
        eval ${dfn}-rml4() { wsdialog-rml4 $dialog }
    done
}

# !!!cursor & highlight state save/restore by caller!!!

# display dialog
wsdialog-run() {
    local dialog=$1
    local msgvar=wsdialog_${dialog}_msg
    local msg=$(eval echo \$$msgvar)
}

# remove dialog l4 and restore cursor
wsdialog-rml4() {
    local dialog=$1
}


