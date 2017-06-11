# reads the contents of a file and puts them at cursor
wsdialog_wsdfopen_msg="Document? "
wsdialog_wsdfopen_modes[1]=eread
wsdialog_wsdfopen_accept=wsdfopen-accept
wsdialog_wsdfopen_restore=wsdfopen-restore

# ewrite
make-eread-msg() {
    local msg='#ZSH could not open "<FN>".#  Press Enter to continue.'
    wsdialog_wsdfopen_eread_msg="$(echo $msg | sed s:\<FN\>:$wsdialog_text:)"
}

wsdialog-add wsdfopen

wsdfopen-accept() {
    if [[ -n "$wsdialog_text" ]] && wsdfopen-read "$wsdialog_text"; then
      	unset wsdialog_l4mode
    else
        make-eread-msg
        wsdialog_l4mode=eread
    fi
}

wsdfopen-restore() {
    LBUFFER+=$wskr_text
    unset wskr_text
}

# get file contents, file name in first argument, contents in wskr_text
wsdfopen-read() {
    wskr_text=$(cat "$1" 2>&-)
    return $?
}
