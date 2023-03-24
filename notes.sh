#! /bin/bash

# set -ex

PID=$$
VERSION="0.1"
EDITOR=${EDITOR:-/usr/bin/vim}
BASEDIR=${BASEDIR:-~/.bash-notes}
DB=${BASEDIR}/db.json
TMPDB=/tmp/db.json
NOTESDIR=${BASEDIR}/notes
BASENAME=$( basename $0 )
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
JQ=$(which jq)

if [ ! -x $JQ ]; then
	echo "jq not found in your PATH"
	echo "install jq to continue"
	exit 1
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
	NOTETITLE=$1
	echo "add new note"
	NOW=$(date +%s)
	FILEDATE=$(date -d @$NOW +%d/%m/%Y_%T)
	LASTID=$($JQ '.notes[-1].id' $DB)
	[ null == $LASTID ] && LASTID=0
	NOTEID=$(( $LASTID + 1 ))
	touch ${NOTESDIR}/${NOW}
	$JQ --arg i "$NOTEID" --arg t "$NOTETITLE" --arg f "$NOW" '.notes += [{"id": $i, "title": $t, "file": $f}]' "$DB" > $TMPDB
	mv $TMPDB $DB
	NEWNOTE=$(${TERMINAL} --class notes --title notes -e ${EDITOR} ${NOTESDIR}/${NOW})
	if [[ $NEWNOTE ]]; then
		echo "New note saved!"
	fi
}

function listnotes() {
	echo "list all notes"
}

function editnote() {
	echo "edit note \"${1}\""
}

function datenote() {
	echo "edit date for note \"${1}\""
}

function rmnote() {
	echo "remove note"
}

function firstrun() {
	mkdir -p $NOTESDIR
	cat << "__EOL__" > $DB
{
	"notes": []
}
__EOL__
}

# check for notes dir existance and create it in case it doesn't exists
if [[ ! -d $NOTESDIR ]]; then
	# we don't have a directory. FIRST RUN?
	firstrun
fi

# Command line parameter processing:
while getopts ":a:hlvm:s:n:e:r:d:" Option
do
  case $Option in
  	h ) helptext
        exit
        ;;
    a ) TITLE=${OPTARG}
		addnote $TITLE
        ;;
    l ) listnotes
        ;;
    m ) NOTE=${OPTARG}
		editnote "${NOTE}"
        ;;
    d ) NOTE=${OPTARG}
		datenote "${NOTE}"
        ;;
    r ) NOTE=${OPTARG}
		rmnote "${NOTE}"
        ;;
    e ) EDITOR=${OPTARG}
        ;;
    s ) NOTESDIR=${OPTARG}
        ;;
    v ) echo $BASENAME v${VERSION}
        ;;
    * ) echo "You passed an illegal switch to the program!"
        echo "Run '$0 -h' for more help."
        exit
        ;;   # DEFAULT
  esac
done

# End of option parsing.
shift $(($OPTIND - 1))
#  $1 now references the first non option item supplied on the command line
#  if one exists.
# ---------------------------------------------------------------------------

