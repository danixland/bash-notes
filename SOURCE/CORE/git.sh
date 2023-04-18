# check if GITCLIENT has been set or set it to the output of hostname
if [ -z "$GITCLIENT" ]; then
    GITCLIENT=$( hostname )
fi
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
# accepts -f parameter to skip last sync check
gitsync() {
    FORCE=$1
    if [[ $USEGIT && -n $GITREMOTE ]]; then
        [ $PLAIN == false ] && echo "Syncing notes with git on remote \"$GITREMOTE\""
        NOWSYNC=$(date +%s)
        if [[ $FORCE == "-f" ]]; then
            $JQ --arg n "$NOWSYNC" '.git["lastpull"] = $n' "$DB" > $TMPDB
            mv $TMPDB $DB
            cd $BASEDIR
            [ $PLAIN == false ] && $GIT pull || $GIT pull -q
        else
            # LASTSYNC is the last time we synced to the remote, or 0 if it's the first time.
            LASTSYNC=$($JQ -r '.git["lastpull"] // 0' "$DB")
            SYNCDIFF=$(( ${NOWSYNC} - ${LASTSYNC} ))
            if (( $SYNCDIFF > $GITSYNCDELAY )); then
                #more than our delay time has passed. We can sync again.
                $JQ --arg n "$NOWSYNC" '.git["lastpull"] = $n' "$DB" > $TMPDB
                mv $TMPDB $DB
                cd $BASEDIR
                [ $PLAIN == false ] && $GIT pull || $GIT pull -q
            else
                # Last synced less than $GITSYNCDELAY seconds ago. We shall wait
                [ $PLAIN == false ] && echo "Last synced less than $GITSYNCDELAY seconds ago. We shall wait"
            fi
        fi
    else
        # no git, so we just keep going
        true
    fi
}

# add note to git and push it to remote
gitadd() {
    if [[ $USEGIT && -n $GITREMOTE ]]; then
        [ $PLAIN == false ] && echo "Adding note to remote \"$GITREMOTE\""
        cd $BASEDIR
        $GIT add .
        $GIT commit -m "$(basename $0) - adding note from ${GITCLIENT}"
        $GIT push origin master
    else
        # no git, so we just keep going
        true
    fi
}

# edited note added to git and pushed it to remote
gitedit() {
    if [[ $USEGIT && -n $GITREMOTE ]]; then
        [ $PLAIN == false ] && echo "Editing note on remote \"$GITREMOTE\""
        cd $BASEDIR
        $GIT add .
        $GIT commit -m "$(basename $0) - ${GITCLIENT} note edited."
        $GIT push origin master
    else
        # no git, so we just keep going
        true
    fi
}

# add note to git and push it to remote
gitremove() {
    NOTE=$1
    FILE=$2
    if [[ $USEGIT && -n $GITREMOTE ]]; then
        [ $PLAIN == false ] && echo "Deleting notes from remote \"$GITREMOTE\""
        if [ "all" == $NOTE ];then
            echo "Deleting all notes"
            cd $BASEDIR
            $GIT rm notes/*
            $GIT commit -m "$(basename $0) - ${GITCLIENT} removing all notes."
            $GIT push origin master
        else
            echo "Deleting note ID ${NOTE}"
            local OK=$(check_noteID "$NOTE")
            cd $BASEDIR
            $GIT rm notes/${FILE}
            $GIT add .
            $GIT commit -m "$(basename $0) - ${GITCLIENT} removing note ID ${NOTE}."
            $GIT push origin master
        fi
    else
        # no git, so we just keep going
        true
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
        $GIT commit -m "$(basename $0) - initial commit from ${GITCLIENT}"
        $GIT remote add origin $GITREMOTE
        $GIT push -u origin master
    fi
elif [[ $USEGIT && -z $GITREMOTE ]]; then
    echo "GITREMOTE variable not set. reverting USEGIT to false"
    USEGIT=false
fi

