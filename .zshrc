export ZWSHDIR=/opt/zwsh
source $ZWSHDIR/zwsh.zsh

if [[ -f ~/.zprofile ]]; then
    source ~/.zprofile
fi

# for testing
zw() {
    export ZWSHDIR=%proj%
    source $ZWSHDIR/zwsh.zsh
}
