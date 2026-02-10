# writes the contents of the selection to a file
wsdialog_wsdfsave_msg="Write to file: "
wsdialog_wsdfsave_modes[1]=badfn
wsdialog_wsdfsave_modes[2]=fexists
wsdialog_wsdfsave_modes[3]=ewrite
wsdialog_wsdfsave_accept=wsdfsave-accept
wsdialog_wsdfsave_restore=wsdfsave-restore

wsdfsave-run() {
    wsdialog_fn="$1"    # if given: prefill wsdialog string TODO
    wsdialog-wsdfsave-run "$wsdialog_fn"
}

# badfn
wsdialog_wsdfsave_badfn_msg="Bad file name."

# fexists (yes=overwrite, no=edit)
wsdialog_wsdfsave_fexists_msg="#That file already exists.# Overwrite (Y/N)?"
declare -A wsdialog_wsdfsave_fexists_funcs
wsdialog_wsdfsave_fexists_funcs[y]=wsdfsave-fexists-yes
wsdialog_wsdfsave_fexists_funcs[n]=wsdfsave-fexists-no

# ewrite
wsdfsave-make-ewrite-msg() {
    local ewrite_msg='#Error writing file "<FN>".#  Press Enter to continue.'
    wsdialog_wsdfsave_ewrite_msg="$(echo $ewrite_msg | sed s:\<FN\>:$wsdialog_text:)"
}

wsdialog-add wsdfsave

wsdfsave-accept() {
    local filename="${wsdialog_text// /}"
    if [[ -z "$filename" || ${#filename} -eq 0 ]]; then
        wsdialog_l4mode=badfn
    elif [[ -e "$filename" ]]; then
        wsdialog_l4mode=fexists
    elif wsdfsave-save "$filename" "$wsdfsave_text"; then
        wsdfsave_fn="$filename"
        unset wsdialog_l4mode
    else
        wsdfsave-make-ewrite-msg
        wsdialog_l4mode=ewrite
    fi
}

wsdfsave-restore() {
    if [[ -n $wsdfsave_endfn ]]; then
        $wsdfsave_endfn $1
        unset wsdfsave_endfn
    fi
    unset wsdfsave_text
    unset wsdfsave_fn
}

wsdfsave-fexists-yes() {
    if wsdfsave-save "$wsdialog_text" "$wsdfsave_text"; then
        wsdfsave_fn="$wsdialog_text"
        wsdialog_l4mode="<accept>"
    else
        wsdfsave-make-ewrite-msg
        wsdialog_l4mode=ewrite
    fi
}

wsdfsave-fexists-no() {
    unset wsdialog_l4mode
}

# file in first argument, text in second argument
# optional third argument: "sudo" to write via sudo
wsdfsave-save() {
    local filename="$1"
    local text="$2"
    local sudo="$3"
    if [[ "$sudo" = "sudo" ]]; then
        ws-sudo-write "$filename" "$text"
        return $?
    else
        printf '%s' "$text" 2>&- > "$filename"
        return $?
    fi
}
