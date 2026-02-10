#!/bin/sh
set -e

usage() {
    echo "Usage: sudo $0 [OPTION]"
    echo ""
    echo "Install or manage zwsh (WordStar keybindings for zsh)."
    echo ""
    echo "Options:"
    echo "  UPDATE       Update an existing installation"
    echo "  --uninstall  Remove zwsh from /opt/zwsh and clean .zshrc"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  sudo ./zwshinst.sh           # Fresh install"
    echo "  sudo ./zwshinst.sh UPDATE    # Update existing install"
    echo "  sudo ./zwshinst.sh --uninstall  # Uninstall"
}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ $UID != 0 ]; then
    echo "Please run this script with sudo." 1>&2
    exit 1
fi

if [ -z "$SUDO_USER" ]; then
	echo "Error: The script must be run using sudo." 1>&2
	exit 1
fi

homedir=$(getent passwd $SUDO_USER | cut -d: -f6)

# --- Uninstall ---
if [ "$1" = "--uninstall" ]; then
    instdir="/opt/zwsh"
    if [ -d "$instdir" ]; then
        rm -rf "$instdir"
        echo "Removed $instdir"
    else
        echo "No installation found at $instdir"
    fi
    if [ -f "$homedir/.zshrc" ]; then
        # Remove the ZWSHDIR and source lines added by the installer
        sed -i '/export ZWSHDIR=\/opt\/zwsh/d' "$homedir/.zshrc"
        sed -i '/source \$ZWSHDIR\/zwsh\.zsh/d' "$homedir/.zshrc"
        echo "Cleaned $homedir/.zshrc"
    fi
    echo "Uninstall complete. Restart your shell."
    exit 0
fi

# tests for compatiblity with older versions...
#
# zsh -c "autoload -U is-at-least && is-at-least 5.5-1"
# if [ $? -ne 0 ] # 0 => OK, 1 => problem
# then
#     echo "Error: Version of zsh is too old." 1>&2
#    exit 1
# fi

homedir=$(getent passwd $SUDO_USER | cut -d: -f6)
basedir=$(dirname $0)
tmp="$basedir/*.zsh"
instdir="/opt/zwsh"
files=$(echo $tmp)
if [[ ! -d "$instdir" ]]; then
	if [[ -n "$1" ]]; then
		echo "Cannot update, no installation found." 1>&2
		exit 1
	else
        mkdir -pv "$instdir"
    fi
fi

cp -v $files "$instdir"
chmod -R +r "$instdir"

if [ -z "$1" ]; then
	if [ -f "$homedir/.zshrc" ]; then
    	cp "$homedir/.zshrc" "$homedir/.zshrc.bak"
	fi
	cp .zshrc "$homedir"

    # set project directory of zw in .zshrc
fi

sed -i -e "s|^.*%proj%$|    export ZWSHDIR=$(pwd) #%proj%|" "$homedir/.zshrc"

for f in "$homedir/".zshrc{,.bak}; do
	if [ -f "$f" ]; then
		chown $SUDO_USER "$f"
	fi
done
