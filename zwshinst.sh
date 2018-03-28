#!/bin/sh
set -e

if [ ! $UID = 0 ]; then
    echo "Please run this script with sudo."
    exit 1
fi

if [ -z "$SUDO_USER" ]; then
	echo "Error: The script must be run using sudo."
	exit 1
fi

homedir=$(getent passwd $SUDO_USER | cut -d: -f6)
basedir=$(dirname $0)
tmp="$basedir/*.zsh"
files=$(echo $tmp)
mkdir -pv /opt/zwsh
cp -v $files /opt/zwsh

if [ -f "$homedir/.zshrc" ]; then
    cp "$homedir/.zshrc" "$homedir/.zshrc.bak"
fi
cp .zshrc "$homedir"

for f in "$homedir/".zshrc{,.bak}; do
	if [ -f "$f" ]; then
		chown $SUDO_USER "$f"
	fi
done
