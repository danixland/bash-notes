#! /bin/bash

# bash-notes © 2023 by danix is licensed under CC BY-NC 4.0. 
# To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/

# to debug the script run it like:
# DEBUG=true notes.sh ...
# and check /tmp/debug_bash-notes.log
if [[ $DEBUG == true ]]; then
	exec 5> /tmp/debug_bash-notes.log
	BASH_XTRACEFD="5"
	PS4='$LINENO: '
	set -x
fi

PID=$$
BASENAME=$( basename "$0" )
NOW=$(date +%s)

VERSION="0.4git"
DBVERSION=${VERSION}_${NOW}

set_defaults() {
# Binaries to use
JQ=${JQ:-/usr/bin/jq}
EDITOR=${EDITOR:-/usr/bin/vim}
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
# Git binary only used if $USEGIT is true - See below
GIT=${GIT:-/usr/bin/git}
# add options for your terminal. Remember to add the last option to execute
# your editor program, otherwise the script will fail.
# see example in the addnote function
TERM_OPTS="--class notes --title notes -e "
# Setting PAGER here overrides whatever is set in your default shell
# comment this option to use your default pager if set in your shell.
PAGER=${PAGER:-/usr/bin/more}

# set this to true to have output in plain text
# or use the -p option on the command line before every other option
PLAIN=false
# base directory for program files
BASEDIR=${BASEDIR:-~/.local/share/bash-notes}
# notes database in json format
DB=${BASEDIR}/db.json
# directory containing the actual notes
NOTESDIR=${BASEDIR}/notes

### GIT SUPPORT

# If you want to store your notes in a git repository set this to true
USEGIT=true
# Address of your remote repository. Without this GIT will refuse to work
GITREMOTE=${GITREMOTE:-""}
# How long should we wait (in seconds) between sync on the git remote. Default 3600 (1 hour)
GITSYNCDELAY=${GITSYNCDELAY:-"3600"}
# The name of this client. If left empty, defaults to the output of hostname
GITCLIENT=${GITCLIENT:-""}

} # end set_defaults, do not change this line.

set_defaults

# Do not edit below this point
RCFILE=${RCFILE:-~/.config/bash-notes.rc}
TMPDB=/tmp/db.json

if [ ! -x "$JQ" ]; then
	echo "jq not found in your PATH"
	echo "install jq to continue"
	exit 1
fi

# IMPORT USER DEFINED OPTIONS IF ANY
if [[ -f $RCFILE ]]; then
	# shellcheck disable=SC1090
	source "$RCFILE"
fi

# We prevent the program from running more than one instance:
PIDFILE=/var/tmp/$(basename "$0" .sh).pid

# Make sure the PID file is removed when we kill the process
trap 'rm -f $PIDFILE; exit 1' TERM INT

if [[ -r $PIDFILE ]]; then
	# PIDFILE exists, so I guess there's already an instance running
	# let's kill it and run again
	# shellcheck disable=SC2046,SC2086
	kill -s 15 $(cat $PIDFILE) > /dev/null 2>&1
	# should already be deleted by trap, but just to be sure
	rm "$PIDFILE"
fi

# create PIDFILE
echo $PID > "$PIDFILE"

# Export config to file
export_config() {
	if [ -r ${RCFILE} ]; then
		echo "Backing up current '${RCFILE}'...."
		mv -f ${RCFILE} ${RCFILE}.$(date +%Y%m%d_%H%M)
	fi
	echo "Writing '${RCFILE}'...."
	sed  -n '/^set_defaults() {/,/^} # end set_defaults, do not change this line./p' $0 \
	| grep -v set_defaults \
	| sed -e 's/^\([^=]*\)=\${\1:-\([^}]*\)}/\1=\2/' \
	> ${RCFILE}
	if [ -r ${RCFILE} ]; then
		echo "Taking no further action."
		exit 0
	else
		echo "Could not write '${RCFILE}'...!"
		exit 1
	fi
}

# we should expand on this function to add a sample note and explain a little bit
# how the program works.
firstrun() {
	[ -f $RCFILE ] && RC=$RCFILE || RC="none"

	clear
	echo "${BASENAME} configuration:

base directory:		${BASEDIR}/
notes archive:		${NOTESDIR}/
notes database:		${DB}
rc file:		$RC
text editor:		${EDITOR}
terminal:		${TERMINAL}
jq executable:		${JQ}
"

	echo "Now I'll create the needed files and directories."
	read -r -p "Do you wish to continue? (y/N) " ANSWER
	case $ANSWER in
		y|Y )
			mkdir -p $NOTESDIR
			cat << __EOL__ > ${DB}
{
	"params": {
		"version": "${VERSION}",
		"dbversion": "${DBVERSION}"
	},
	"git": {
		"lastpull": ""
	},
	"notes": []
}
__EOL__
			echo; echo "All done, you can now write your first note."
			;;
		* )
			echo "No changes made. Exiting"
			exit
			;;
	esac
}

# check for notes dir existance and create it in case it doesn't exists
if [[ ! -d $NOTESDIR ]]; then
	# we don't have a directory. FIRST RUN?
	firstrun
fi
# check if input is a number, returns false or the number itself
check_noteID() {
	IN=$1
	case $IN in
		''|*[!0-9]*)
			false
			;;
		*)
			echo "$IN"
			;;
	esac
}

helptext() {
    echo "Usage:"
    echo "  $0 [PARAMS] [note ID]..."
	echo ""
    echo "${BASENAME} parameters are:"
    echo -e "  -h | --help\t\t\t: This help text"
    echo -e "  -p | --plain\t\t\t: Output is in plain text"
    echo -e "\t\t\t\t  (without this option the output is formatted)"
    echo -e "\t\t\t\t  (this option must precede all others)"
    echo -e "  -l | --list\t\t\t: List existing notes"
    echo -e "  -a | --add=[\"<title>\"]\t: Add new note"
    echo -e "  -e | --edit=[<note>]\t\t: Edit note"
    echo -e "  -d | --delete=[<note> | all]	: Delete single note or all notes at once"
    echo -e "  -s | --show=[<note>]\t\t: Display note using your favourite PAGER"
    echo -e "  -r | --restore=[<dir>]\t: Restore a previous backup from dir"
    echo -e "  -v | --version\t\t: Print version"
    echo -e "  --userconf\t\t\t: Export User config file"
    echo -e "  --backup [<dest>]\t\t: Backup your data in your destination folder"
    echo -e "  --showconf\t\t\t: Display running options"
    echo -e "  --sync\t\t\t: Sync notes to git repository"
    echo ""
    echo -e "if a non option is passed and is a valid note ID, the note will be displayed."
}

configtext() {
    [ $USEGIT ] && GITUSE="enabled" || GITUSE="disabled"
    if [ -n $GITCLIENT ]; then
        CLIENTGIT="$( hostname )"
    else
        CLIENTGIT="$GITCLIENT"
    fi
    clear
    echo -e "${BASENAME} configuration is:"

    echo -e "\tbase directory:     ${BASEDIR}/"
    echo -e "\tnotes archive:      ${NOTESDIR}/"
    echo -e "\tnotes database:     ${DB}"
    echo -e "\trc file:            $RCFILE"
    echo -e "\tdebug file:         /tmp/debug_bash-note.log"
    echo
    echo -e "\ttext editor:        ${EDITOR}"
    echo -e "\tterminal:           ${TERMINAL}"
    echo -e "\tjq executable:      ${JQ}"
    echo -e "\tPAGER:              ${PAGER}"
    echo
    echo -e "\tGIT:                ${GITUSE} - ${GIT}"
    echo -e "\tGIT remote:         ${GITREMOTE}"
    echo -e "\tGIT sync delay:     ${GITSYNCDELAY}"
    echo -e "\tGIT client name:    ${CLIENTGIT}"
}

# this function returns a random 2 words title
random_title() {
    # Constants 
    X=0
    DICT=/usr/share/dict/words
    OUTPUT=""
     
    # total number of non-random words available 
    COUNT=$(cat $DICT | wc -l)
     
    # while loop to generate random words  
    while [ "$X" -lt 2 ] 
    do 
        RAND=$(od -N3 -An -i /dev/urandom | awk -v f=0 -v r="$COUNT" '{printf "%i\n", f + r * $1 / 16777216}')
        OUTPUT+="$(sed `echo $RAND`"q;d" $DICT)"
        (("X = X + 1"))
        [[ $X -eq 1 ]] && OUTPUT+=" "
    done

    echo $OUTPUT
}

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
            local OK=$(check_noteID "$NOTE")
            if [[ "$OK" ]]; then
                echo "Deleting note ID ${NOTE}"
                cd $BASEDIR
                $GIT rm notes/${FILE}
                $GIT add .
                $GIT commit -m "$(basename $0) - ${GITCLIENT} removing note ID ${NOTE}."
                $GIT push origin master
            fi
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

addnote() {
	# attempt syncing before adding a note
	gitsync -f
	# remove eventually existing temp DB file
	if [[ -f $TMPDB ]]; then
		rm $TMPDB
	fi

	# RANDOM TITLE
	RTITLE=$(random_title)

	if [[ -z $1 ]]; then
		read -r -p "Title: " TITLE
		case "$TITLE" in
			'' )
				NOTETITLE="$RTITLE"
				;;
			* )
				NOTETITLE=$TITLE
				;;
		esac
	fi

	# [[ -z "$1" ]] && NOTETITLE="$RTITLE" || NOTETITLE="$1"
	echo "adding new note - \"$NOTETITLE\""
	# shellcheck disable=SC2086
	LASTID=$($JQ '.notes[-1].id // 0 | tonumber' $DB)
	# [ "" == $LASTID ] && LASTID=0
	NOTEID=$(( LASTID + 1 ))
	# shellcheck disable=SC2086
	touch ${NOTESDIR}/${NOW}
	# shellcheck disable=SC2016
	$JQ --arg i "$NOTEID" --arg t "$NOTETITLE" --arg f "$NOW" '.notes += [{"id": $i, "title": $t, "file": $f}]' "$DB" > $TMPDB
	# shellcheck disable=SC2086
	mv $TMPDB $DB
	# example for alacritty:
	# alacritty --class notes --title notes -e /usr/bin/vim ...
	# shellcheck disable=SC2086,SC2091
	$(${TERMINAL} ${TERM_OPTS} ${EDITOR} ${NOTESDIR}/${NOW})
	# add note to git and push to remote
	gitadd
}
backup_data() {
	BACKUPDIR="$1"
    echo "backing up data in $BACKUPDIR"


    if [ -d $BACKUPDIR ]; then
    	if [ $(/bin/ls -A $BACKUPDIR) ]; then
	    	echo "$BACKUPDIR is not empty. Cannot continue"
	    	exit
	    else
	    	echo "$BACKUPDIR is ok. Continuing!"
	    fi
	else
		# BACKUPDIR doesn't exists
		echo "$BACKUPDIR doesn't exists"
		read -r -p "Do you want me to create it for you? (y/N) " ANSWER
		case $ANSWER in
			y|Y )
				mkdir -p $BACKUPDIR
				;;
			* )
				echo "No changes made. Exiting"
				exit
				;;
		esac
    fi
    # ok, we have a backup directory
    if [ -r $RCFILE ]; then
    	BCKUP_COMM=$(rsync -avz --progress ${RCFILE}* ${BASEDIR}/ ${BACKUPDIR})
    else
    	BCKUP_COMM=$(rsync -avz --progress ${BASEDIR}/ ${BACKUPDIR})
    fi
    # run the command
    if [ "$BCKUP_COMM" ]; then	
	    echo -e "All files backed up."
	    echo -e "BACKUP directory:\t$BACKUPDIR"
	    tree $BACKUPDIR | $PAGER
	    echo; echo "BACKUP COMPLETED"
	fi
}

backup_restore() {
	BACKUPDIR="$1"
	echo "restoring backup from $BACKUPDIR"
	echo "This will overwrite all your notes and configurations with the backup."
	read -r -p "Do you want to continue? (y/N) " ANSWER
	case $ANSWER in
		y|Y )
			# restoring rc file
			BACKUPRC=$(basename $RCFILE)
			if [ -r ${BACKUPDIR}/${BACKUPRC} ]; then
				if [ -r ${RCFILE} ]; then
					echo "Backing up current '${RCFILE}'...."
					mv -f ${RCFILE} ${RCFILE}.$(date +%Y%m%d_%H%M)
				fi
				cp --verbose ${BACKUPDIR}/${BACKUPRC} $RCFILE
			fi
			# restoring notes directory
			if [ -d $BACKUPDIR/notes ]; then
				if [ $(/bin/ls -A $NOTESDIR) ]; then
					rm --verbose $NOTESDIR/*
				fi
				cp -r --verbose $BACKUPDIR/notes $BASEDIR
			fi
			# restoring database
			BACKUPDB=$(basename $DB)
			if [ -f ${BACKUPDIR}/${BACKUPDB} ]; then
				if [ -r ${DB} ]; then
					echo "Backing up current '${DB}'...."
					mv -f ${DB} ${DB}.$(date +%Y%m%d_%H%M)
				fi
				cp --verbose ${BACKUPDIR}/${BACKUPDB} $DB
			fi
			# restoring git repo subdirectory
			if [ -d $BACKUPDIR/.git ]; then
				if [ /bin/ls -A ${BASEDIR}/.git ]; then
					rm -rf ${BASEDIR}/.git
				fi
				cp -r --verbose ${BACKUPDIR}/.git ${BASEDIR}/
			fi
			;;
		* )
			echo "No changes made. Exiting"
			exit
			;;
	esac
}

editnote() {
	NOTE=$1
	# shellcheck disable=SC2155
	local OK=$(check_noteID "$NOTE")
	if [ ! "$OK" ]; then
		echo "invalid note \"$NOTE\""
		echo "Use the note ID that you can fetch after listing your notes"
		exit 1
	fi

	# shellcheck disable=SC2016,SC2086
	TITLE=$($JQ --arg i $OK '.notes[] | select(.id == $i) | .title' $DB)
	# shellcheck disable=SC2016,SC2086
	FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)
	if [ "$TITLE" ]; then
		echo "editing note $TITLE"
		# shellcheck disable=SC2086,SC2091
		$(${TERMINAL} ${TERM_OPTS} ${EDITOR} ${NOTESDIR}/${FILE})
		gitedit
	else
		 echo "note not found"
		 exit 1
	fi
}
listnotes() {
	# attempt syncing before listing all notes
	gitsync
	# [ $PLAIN == true ] && echo "output is plain text" || echo "output is colored"
	if [[ $(ls -A "$NOTESDIR") ]]; then
		if [ $PLAIN == false ]; then
			echo "listing all notes"
			echo ""
		fi
		[ $PLAIN == false ] && echo "[ID]	[TITLE]		[CREATED]"
		for i in "${NOTESDIR}"/*; do
			# shellcheck disable=SC2155
			local fname=$(basename $i)
			DATE=$(date -d @${fname} +"%d/%m/%Y %R %z%Z")
			# shellcheck disable=SC2016,SC2086
			TITLE=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .title' $DB)
			# shellcheck disable=SC2016,SC2086
			ID=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .id' $DB)
			[ $PLAIN == false ] && echo "[${ID}]	${TITLE}	${DATE}" || echo "${ID} - ${TITLE} - ${DATE}"
		done
	else
		echo "no notes yet. You can add your first one with: ${BASENAME} -a \"your note title\""
	fi
}
rmnote() {
	# remove eventually existing temp DB file
	if [[ -f $TMPDB ]]; then
		rm $TMPDB
	fi

	NOTE=$1
	if [ "all" == "$NOTE" ]; then
		echo "You're going to delete all notes."
		read -r -p "Do you wish to continue? (y/N) " ANSWER
		case $ANSWER in
			y|Y )
				# shellcheck disable=SC2086
				$JQ 'del(.notes[])' $DB > $TMPDB
				# shellcheck disable=SC2086
				mv $TMPDB $DB
				# shellcheck disable=SC2086
				rm $NOTESDIR/*
				gitremove "all"
				echo "Deleted all notes"
				;;
			* )
				echo "Aborting, no notes were deleted."
				exit 1
				;;
		esac
	else
		# shellcheck disable=SC2155
		local OK=$(check_noteID "$NOTE")
		if [ ! "$OK" ]; then
			echo "invalid note \"$NOTE\""
			echo "Use the note ID that you can fetch after listing your notes"
			sleep 1
			exit 1
		fi

		# shellcheck disable=SC2016,SC2086
		TITLE=$($JQ --arg i $OK '.notes[] | select(.id == $i) | .title' $DB)
		# shellcheck disable=SC2016,SC2086
		FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)
		if [ "$TITLE" ]; then
			# shellcheck disable=SC2016,SC2086
			$JQ -r --arg i $OK 'del(.notes[] | select(.id == $i))' $DB > $TMPDB
			# shellcheck disable=SC2086
			mv $TMPDB $DB
			rm $NOTESDIR/$FILE
			gitremove $OK $FILE
			echo "Deleted note $TITLE"
			sleep 1
			exit
		else
			 echo "note not found"
			 sleep 1
			 exit 1
		fi
	fi
}
shownote() {
	NOTE=$1

	# shellcheck disable=SC2155
	local OK=$(check_noteID "$NOTE")
	if [ ! "$OK" ]; then
		echo "invalid note \"$NOTE\""
		echo "Use the note ID that you can fetch after listing your notes"
		exit 1
	fi

	FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)

	if [ "$FILE" ]; then
		$PAGER ${NOTESDIR}/${FILE}
	fi
}
# shellcheck disable=SC2006
GOPT=$(getopt -o hvplr:a::e:d:s: --long help,version,list,plain,userconf,showconf,sync,restore:,backup:,add::,edit:,delete:,show: -n 'bash-notes' -- "$@")

# shellcheck disable=SC2181
if [ $? != 0 ] ; then helptext >&2 ; exit 1 ; fi

# Note the quotes around `$GOPT': they are essential!
eval set -- "$GOPT"
unset GOPT

while true; do
	case "$1" in
	  	-h | --help )
			helptext
	        exit
	        ;;
		-v | --version )
			echo $BASENAME v${VERSION}
			exit
			;;
	    -p | --plain )
			PLAIN=true
			shift
	        ;;
	    -l | --list )
			listnotes
			exit
	        ;;
	    -a | --add )
			TITLE=$2
			shift 2
			addnote "$TITLE"
			exit
	        ;;
		-e | --edit )
			NOTE=$2
			shift 2
			editnote "$NOTE"
			exit
			;;
		-d | --delete )
			NOTE=$2
			shift 2
			rmnote "$NOTE"
			exit
			;;
		-s | --show )
			NOTE=$2
			shift 2
			shownote "$NOTE"
			exit
			;;
		-r | --restore )
			RDIR=$2
			shift 2
			backup_restore $RDIR
			exit
			;;
		--sync )
			# I'm forcing it because if you run it manually, chances are that you need to.
			gitsync -f
			shift
			exit
			;;
		--userconf )
			export_config
			# shellcheck disable=SC2317
			echo "config exported to \"$RCFILE\""
			# shellcheck disable=SC2317
			exit
			;;
		--showconf )
			configtext
			exit
			;;
		--backup )
			BDIR=$2
			shift 2
			backup_data $BDIR
			exit
			;;
		-- )
			shift
			break
			;;
		* )
			break
			;;
	esac
done

for arg; do
	if [ $(check_noteID $arg) ]; then
		shownote $arg
	else
		helptext
		exit
	fi
done
