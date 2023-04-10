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

VERSION="0.3"
DBVERSION=${VERSION}_${NOW}

set_defaults() {
# Binaries to use
JQ=${JQ:-/usr/bin/jq}
EDITOR=${EDITOR:-/usr/bin/vim}
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
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
function export_config() {
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
function firstrun() {
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
function check_noteID() {
	IN=$1
	case $IN in
		''|*[!0-9]*)
			return 1
			;;
		*)
			echo "$IN"
			;;
	esac
}

function helptext() {
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
    echo ""
    echo -e "if a non option is passed and is a valid note ID, the note will be displayed."
}

function configtext() {
    cat << __NOWCONF__ 
${BASENAME} configuration is:

base directory:     ${BASEDIR}/
notes archive:      ${NOTESDIR}/
notes database:     ${DB}
rc file:        $RCFILE
debug file:     /tmp/debug_bash-note.log

text editor:        ${EDITOR}
terminal:       ${TERMINAL}
jq executable:      ${JQ}
PAGER:                  ${PAGER}
__NOWCONF__

}

# this function returns a random 2 words title
function random_title() {
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

function addnote() {
	# remove eventually existing temp DB file
	if [[ -f $TMPDB ]]; then
		rm $TMPDB
	fi

	RTITLE=$(random_title)
	[[ -z "$1" ]] && NOTETITLE="$RTITLE" || NOTETITLE="$1"
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
}
function backup_data() {
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
    	BCKUP_COMM=$(rsync -avz --progress ${RCFILE}* ${BASEDIR}/* ${BACKUPDIR})
    else
    	BCKUP_COMM=$(rsync -avz --progress ${BASEDIR}/* ${BACKUPDIR})
    fi
    # run the command
    if [ "$BCKUP_COMM" ]; then	
	    echo -e "All files backed up."
	    echo -e "BACKUP directory:\t$BACKUPDIR"
	    tree $BACKUPDIR | $PAGER
	    echo; echo "BACKUP COMPLETED"
	fi
}

function backup_restore() {
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
			;;
		* )
			echo "No changes made. Exiting"
			exit
			;;
	esac
}

function editnote() {
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
	else
		 echo "note not found"
		 exit 1
	fi
}
function listnotes() {
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
function rmnote() {
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
function shownote() {
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
GOPT=$(getopt -o hvplr::a::e::d::s:: --long help,version,list,plain,userconf,restore::,backup::,add::,edit::,delete::,show:: -n 'bash-notes' -- "$@")

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
			case "$2" in
				'' )
					read -r -p "Title: " TITLE
					;;
				* )
					TITLE=$2
					;;
			esac
			shift 2
			addnote "$TITLE"
			exit
	        ;;
		-e | --edit )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			editnote "$NOTE"
			exit
			;;
		-d | --delete )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			rmnote "$NOTE"
			exit
			;;
		-s | --show )
			case "$2" in
				'' )
					read -r -p "Note ID: " NOTE
					;;
				* )
					NOTE=$2
					;;
			esac
			shift 2
			shownote "$NOTE"
			exit
			;;
		-r | --restore )
			case "$2" in
				'' )
					read -r -p "Backup Dir: " RDIR
					;;
				* )
					RDIR=$2
					;;
			esac
			shift 2
			backup_restore $RDIR
			exit
			;;
		--userconf )
			export_config
			# shellcheck disable=SC2317
			echo "config exported to \"$RCFILE\""
			# shellcheck disable=SC2317
			exit
			;;
		--backup )
			case "$2" in
				'' )
					read -r -p "Backup Dir: " BDIR
					;;
				* )
					BDIR=$2
					;;
			esac
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
