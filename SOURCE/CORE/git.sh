# returns true if the argument provided directory is a git repository
is_git_repo() {
    DIR=$1
    if [[ -d $DIR ]]; then
        cd $DIR
        if git rev-parse 2>/dev/null; then
            true
        else
            false
        fi
    fi
}

# sync local repository to remote
gitsync() {
    echo "Syncing notes with git on remote \"$GITREMOTE\""
    cd $BASEDIR
    $GIT pull
}

# check for USEGIT and subsequent variables
if [[ $USEGIT && -n $GITREMOTE ]]; then
    # GIT is a go.
    if ! is_git_repo $BASEDIR; then
        # initializing git repository
        cd $BASEDIR
        $GIT init
        echo "adding all files to git"
        $GIT add .
        $GIT commit -m "$(basename $0) - initial commit"
        $GIT remote add origin $GITREMOTE
        $GIT push -u origin master
    fi
elif [[ $USEGIT && -z $GITREMOTE ]]; then
    echo "GITREMOTE variable not set. reverting USEGIT to false"
    USEGIT=false
fi

