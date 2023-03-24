#! /bin/bash

# set -ex

PID=$$
VERSION="0.1"

EDITOR=${EDITOR:-/usr/bin/vim}
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
JQ=$(which jq)

BASEDIR=${BASEDIR:-~/.local/share/bash-notes}
RCFILE=${RCFILE:-~/.bash-notes.rc}
DB=${BASEDIR}/db.json
NOTESDIR=${BASEDIR}/notes

TMPDB=/tmp/db.json
BASENAME=$( basename $0 )

if [ ! -x $JQ ]; then
	echo "jq not found in your PATH"
	echo "install jq to continue"
	exit 1
fi

# IMPORT USER DEFINED OPTIONS IF ANY
if [[ -f $RCFILE ]]; then
	source $RCFILE
fi

# We prevent the program from running more than one instance:
PIDFILE=/var/tmp/$(basename $0 .sh).pid

# Make sure the PID file is removed when we kill the process
trap 'rm -f $PIDFILE; exit 1' TERM INT

if [[ -r $PIDFILE ]]; then
	# PIDFILE exists, so I guess there's already an instance running
	# let's kill it and run again
	kill -s 15 $(cat $PIDFILE) > /dev/null 2>&1
	# should already be deleted by trap, but just to be sure
	rm $PIDFILE
fi

# create PIDFILE
echo $PID > $PIDFILE

function helptext() {
    echo "Parameters are:"
    echo "  -h			: This help text"
    echo "  -s <directory>	: specify directory where to store all notes."
    echo "  -e <editor>		: specify EDITOR for this session only."
    echo "  -l			: List existing notes"
    echo "  -a        		: Add new note"
    echo "  -m <note> 		: Modify note"
    echo "  -d <note> 		: Modify date for note"
    echo "  -r <note>		: Remove note"
    echo "  -v        		: Print version"
}

function addnote() {
	NOTETITLE="$1"
	echo "adding new note - \"$NOTETITLE\""
	NOW=$(date +%s)
	LASTID=$($JQ '.notes[-1].id | tonumber' $DB)
	[ null == $LASTID ] && LASTID=0
	NOTEID=$(( $LASTID + 1 ))
	touch ${NOTESDIR}/${NOW}
	$JQ --arg i "$NOTEID" --arg t "$NOTETITLE" --arg f "$NOW" '.notes += [{"id": $i, "title": $t, "file": $f}]' "$DB" > $TMPDB
	mv $TMPDB $DB
	$(${TERMINAL} --class notes --title notes -e ${EDITOR} ${NOTESDIR}/${NOW})
}

function listnotes() {
	echo "list all notes"
}

function editnote() {
	echo "edit note \"${1}\""
}

function datenote() {
	echo "edit date for note \"${1}\""
	# FILEDATE=$(date -d @$NOW +%d/%m/%Y_%T)

}

function rmnote() {
	NOTE=$1
	echo "removing note $NOTE"
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

	read -r -p "Do you wish to continue? (y/N) " ANSWER
	case $ANSWER in
		y|Y )
			mkdir -p $NOTESDIR
			cat << "__EOL__" > ${DB}
{
	"notes": []
}
__EOL__
			;;
		n|N )
			echo "No changes made. Exiting"
			exit
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

# NOTE: This requires GNU getopt.  On Mac OS X and FreeBSD, you have to install this
# separately; see below.
GOPT=`getopt -o hvla:m:d:r: --long help,version,list,add:,modify:,date:,remove:,editor:,storage: \
             -n 'bash-notes' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$GOPT': they are essential!
eval set -- "$GOPT"

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
	    -l | --list )
			listnotes
			exit
	        ;;
	    -a | --add )
			TITLE="$2"
			shift 2
			addnote "$TITLE"
	        ;;
		-m | --modify )
			NOTE="$2"
			shift 2
			editnote "$NOTE"
			;;
		-d | --date )
			NOTE="$2"
			shift 2
			datenote "$NOTE"
			;;
		-r | --remove )
			NOTE="$2"
			shift 2
			rmnote "$NOTE"
			;;
		--editor )
			EDITOR="$2"
			shift 2
			echo "changed EDITOR TO \"$EDITOR\""
			;;
		--storage )
			BASEDIR="$2"
			shift 2
			echo "changed BASEDIR TO \"$BASEDIR\""
			# firstrun
			;;
		-- )
			shift; break
			;;
		* )
			break
			;;
	esac
done

