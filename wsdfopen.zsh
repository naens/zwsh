# reads the contents of a file and puts them at cursor
wsdialog_wsdfopen_msg="Document? "
wsdialog_wsdfopen_modes[1]=eempty
wsdialog_wsdfopen_modes[2]=enotexists
wsdialog_wsdfopen_modes[3]=enotafile
wsdialog_wsdfopen_modes[4]=epermissions
wsdialog_wsdfopen_accept=wsdfopen-accept
wsdialog_wsdfopen_restore=wsdfopen-restore

wsdfopen-run() {
    wsdialog-wsdfopen-run
}

wsdfopen-make-eempty-msg() {
    wsdialog_wsdfopen_eempty_msg='#Filename empty.#  Press Enter to continue.'
}

wsdfopen-make-enotexists-msg() {
    local msg='#File "<FN>" does not exist.#  Press Enter to continue.'
    local filename="$1"
    wsdialog_wsdfopen_enotexists_msg="$(echo $msg | sed s:\<FN\>:$1:)"
}

wsdfopen-make-enotafile-msg() {
    local msg='#File "<FN>" is not a file.#  Press Enter to continue.'
    local filename="$1"
    wsdialog_wsdfopen_enotafile_msg="$(echo $msg | sed s:\<FN\>:$1:)"
}

wsdfopen-make-epermissions-msg() {
    wsdialog_wsdfopen_epermissions_msg='#Permission error.#  Press Enter to continue.'
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
    elif [[ ! -e "$filename" ]]; then
        wsdfopen-make-enotexists-msg "$filename"
        wsdialog_l4mode=enotexists
    elif [[ ! -f "$filename" ]]; then
        wsdfopen-make-enotafile-msg "$filename"
        wsdialog_l4mode=enotafile
    elif [[ -r "$filename" && -w "$filename" ]]; then
        wsdfopen-read "$filename"
        wsdfopen_fn="$filename"
    else    # no permissions: try sudo
        if wsdfopen-read "$filename" sudo; then
            wsdfopen_fn="$filename"
            wsdfopen_sudo=true
        else
            wsdfopen-make-epermissions-msg
            wsdialog_l4mode=epermissions
        fi
    fi

}

wsdfopen-restore() {
    if [[ -n $wsdfopen_endfn ]]; then
        $wsdfopen_endfn $1
        unset wsdfopen_endfn
    fi
    unset wsdfopen_text
    unset wsdfopen_fn
    unset wsdfopen_sudo
}

# get file contents, file name in first argument, contents in wsdfopen_text
wsdfopen-read() {
    local fn="$1"
    local sudo="$2"
    if [[ "$sudo" = "sudo" ]]; then
        ws-sudo-read "$fn"
        local rc=$?
        wsdfopen_text="$REPLY"
        return $rc
    else
        wsdfopen_text=$(cat "$fn"; printf x)
        wsdfopen_text=${wsdfopen_text%x}
        return 0
    fi
}
