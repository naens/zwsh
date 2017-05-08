# writes the contents of the selection to a file
wsdialog_kwdial_msg="Write to file: "
wsdialog_kwdial_modes[1]=badfn
wsdialog_kwdial_modes[2]=fexists
wsdialog_kwdial_modes[3]=ewrite
wsdialog_kwdial_accept=kw2-accept
wsdialog_kwdial_restore=kw2-restore

# badfn
wsdialog_kwdial_badfn_msg="Bad file name."

# fexists (yes=overwrite, no=edit)
wsdialog_kwdial_fexists_msg="#That file already exists.# Overwrite (Y/N)?"
declare -A wsdialog_kwdial_fexists_funcs
wsdialog_kwdial_fexists_funcs[y]=kw2-fexists-yes
wsdialog_kwdial_fexists_funcs[n]=kw2-fexists-no

# ewrite
make-ewrite-msg() {
    local ewrite_msg='#Error writing file "<FN>".#  Press Enter to continue.'
    wsdialog_kwdial_ewrite_msg="$(echo $ewrite_msg | sed s:\<FN\>:$wsdialog_text:)"
}

wsdialog-add kwdial

kw2-accept() {
    if [[ -z "$wsdialog_text" || ${#wsdialog_text} -eq 0 ]]; then
        wsdialog_l4mode=badfn
    elif [[ -e "$wsdialog_text" ]]; then
        wsdialog_l4mode=fexists
    else
        if kw2-save "$wsdialog_text" "$wsblock_text"; then
            unset wsdialog_l4mode
        else
            make-ewrite-msg
            wsdialog_l4mode=ewrite
        fi
    fi
}

kw2-restore() {
}

kw2-fexists-yes() {
    if kw2-save "$wsdialog_text" "$wsblock_text"; then
        wsdialog_l4mode="<accept>"
    else
        make-ewrite-msg
        wsdialog_l4mode=ewrite
    fi
}

kw2-fexists-no() {
    unset wsdialog_l4mode
}

# file in first argument, text in second argument
kw2-save() {
    $ws_echo "$2" 2>&- > "$1"
    return $?
}
