# reads the contents of a file and puts them at cursor
wsdialog_krdial_msg="Document? "
wsdialog_krdial_modes[1]=eread
wsdialog_krdial_accept=kr2-accept
wsdialog_krdial_restore=kr2-restore

# ewrite
make-eread-msg() {
    local msg='#ZSH could not open "<FN>".#  Press Enter to continue.'
    wsdialog_krdial_eread_msg="$(echo $msg | sed s:\<FN\>:$wsdialog_text:)"
}

wsdialog-add krdial

kr2-accept() {
    if [[ -n "$wsdialog_text" ]] && kr2-read "$wsdialog_text"; then
      	unset wsdialog_l4mode
    else
        make-eread-msg
        wsdialog_l4mode=eread
    fi
}

kr2-restore() {
    LBUFFER+=$wskr_text
    unset wskr_text
}

# get file contents, file name in first argument, contents in wskr_text
kr2-read() {
    wskr_text=$(cat "$1" 2>&-)
    return $?
}
