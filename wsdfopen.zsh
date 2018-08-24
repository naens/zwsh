# reads the contents of a file and puts them at cursor
wsdialog_wsdfopen_msg="Document? "
wsdialog_wsdfopen_modes[1]=eread
wsdialog_wsdfopen_modes[2]=eempty
wsdialog_wsdfopen_accept=wsdfopen-accept
wsdialog_wsdfopen_restore=wsdfopen-restore

wsdfopen-run() {
    wsdialog-wsdfopen-run
}

# TODO: prefill file name

# ewrite
wsdfopen-make-eread-msg() {
    local msg='#ZSH could not open "<FN>".#  Press Enter to continue.'
    local filename="$1"
    wsdialog_wsdfopen_eread_msg="$(echo $msg | sed s:\<FN\>:$1:)"
}

# eempty
wsdfopen-make-eempty-msg() {
    wsdialog_wsdfopen_eempty_msg='#Filename empty.#  Press Enter to continue.'
}

wsdialog-add wsdfopen

# If file name empty => filename empty error
# If file does not exist => file not found error
# If file exists and no permission => open with sudo, mark as sudo
# Otherwise, just open normally (without sudo)
wsdfopen-accept() {
    local filename="${wsdialog_text// /}"
    if [[ -z "$filename" ]]; then
        wsdfopen-make-eempty-msg
        wsdialog_l4mode=eempty
        return
    fi
    if [[ -n "$filename" ]] && wsdfopen-read "$filename"; then
        wsdfopen_fn="$filename"
        unset wsdialog_l4mode
    else
        wsdfopen-make-eread-msg "$filename"
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
    wsdfopen_text=$(cat "$fn"; printf x)
    wsdfopen_text=${wsdfopen_text%x}
    ws-debug WSDFOPEN_READ: wsdfopen_text="\"$wsdfopen_text\""
    return $?
}
