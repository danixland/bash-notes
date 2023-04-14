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
    NOWSYNC=$(date +%s)
    # LASTSYNC is the last time we synced to the remote, or 0 if it's the first time.
    LASTSYNC=$($JQ -r '.git["lastpull"] // 0' "$DB")
    [ $PLAIN == false ] && echo "Syncing notes with git on remote \"$GITREMOTE\""
    SYNCDIFF=$(( ${NOWSYNC} - ${LASTSYNC} ))
    if (( $SYNCDIFF > $GITSYNCDELAY )); then
        #more than our delay time has passed. We can sync again.
        $JQ --arg n "$NOWSYNC" '.git["lastpull"] = $n' "$DB" > $TMPDB
        mv $TMPDB $DB
        cd $BASEDIR
        $GIT pull
    else
        # Last synced less than $GITSYNCDELAY seconds ago. We shall wait
        [ $PLAIN == false ] && echo "Last synced less than $GITSYNCDELAY seconds ago. We shall wait"
    fi
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

