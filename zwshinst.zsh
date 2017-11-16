set -e
mkdir -pv /opt/zwsh
cp -v *.zsh /opt/zwsh
if [[ -f ~/.zshrc ]]; then
    cp .zshrc .zshrc.bak
fi
cp .zshrc ~
export ZWSHDIR=/opt
