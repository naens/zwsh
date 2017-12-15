#!/bin/sh
set -e
basedir=$(dirname $0)
tmp="$basedir/*.zsh"
files=$(echo $tmp)
mkdir -pv /opt/zwsh
cp -v $files /opt/zwsh
echo "set ZWSHDIR to /opt/zwsh"

if [[ -f ~/.zshrc ]]; then
    cp .zshrc .zshrc.bak
fi
cp .zshrc ~
export ZWSHDIR=/opt/zwsh

