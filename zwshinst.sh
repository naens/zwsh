#!/bin/sh
set -e

if [ $UID != 0 ]; then
    echo "Please run this script with sudo." 1>&2
    exit 1
fi

if [ -z "$SUDO_USER" ]; then
	echo "Error: The script must be run using sudo." 1>&2
	exit 1
fi

# TODO: don't use pcre => earlier version

zsh -c "autoload -U is-at-least && is-at-least 5.5-1"
if [ $? -ne 0 ] # 0 => OK, 1 => problem
then
    echo "Error: Version of zsh is too old." 1>&2
    exit 1
fi

homedir=$(getent passwd $SUDO_USER | cut -d: -f6)
basedir=$(dirname $0)
tmp="$basedir/*.zsh"
files=$(echo $tmp)
mkdir -pv /opt/zwsh
cp -v $files /opt/zwsh

if [ -z "$1" ]; then
	if [ -f "$homedir/.zshrc" ]; then
    	cp "$homedir/.zshrc" "$homedir/.zshrc.bak"
	fi
	cp .zshrc "$homedir"
fi

# set project directory of zw in .zshrc
sed -i -e "s|%proj%|$(pwd)|" "$homedir/.zshrc"

for f in "$homedir/".zshrc{,.bak}; do
	if [ -f "$f" ]; then
		chown $SUDO_USER "$f"
	fi
done
