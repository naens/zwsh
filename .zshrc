export ZWSHDIR=/opt/zwsh
source $ZWSHDIR/zwsh.zsh

# for testing
zw() {
    export ZWSHDIR="%proj%"
    source $ZWSHDIR/zwsh.zsh
}

source ~/.zprofile
