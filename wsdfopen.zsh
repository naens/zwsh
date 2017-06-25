# reads the contents of a file and puts them at cursor
wsdialog_wsdfopen_msg="Document? "
wsdialog_wsdfopen_modes[1]=eread
wsdialog_wsdfopen_accept=wsdfopen-accept
wsdialog_wsdfopen_restore=wsdfopen-restore

wsdfopen-run() {
    wsdialog-wsdfopen-run
}

# TODO: prefill file name

# ewrite
wsdfopen-make-eread-msg() {
    local msg='#ZSH could not open "<FN>".#  Press Enter to continue.'
    wsdialog_wsdfopen_eread_msg="$(echo $msg | sed s:\<FN\>:$wsdialog_text:)"
}

wsdialog-add wsdfopen

wsdfopen-accept() {
    if [[ -n "$wsdialog_text" ]] && wsdfopen-read "$wsdialog_text"; then
        wsdfopen_fn="$wsdialog_text"
      	unset wsdialog_l4mode
    else
        wsdfopen-make-eread-msg
        wsdialog_l4mode=eread
    fi
}

wsdfopen-restore() {
    if [[ -n $wsdfopen_endfn ]]; then
        $wsdfopen_endfn $1
        unset wsdfopen_endfn
    fi
    unset wsdfopen_text
    unset wsdfopen_fn
}

# get file contents, file name in first argument, contents in wskr_text
wsdfopen-read() {
    local fn="$1"
    wsdfopen_text=$(cat "$fn" 2>&-)
    return $?
}
