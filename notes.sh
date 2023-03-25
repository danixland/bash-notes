#! /bin/bash

# set -ex

PID=$$
VERSION="0.1"

set_defaults() {
# Binaries to use
EDITOR=${EDITOR:-/usr/bin/vim}
TERMINAL=${TERMINAL:-/usr/bin/alacritty}
TERM_OPTS="--class notes --title notes -e "
JQ=${JQ:-/usr/bin/jq}

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
BASENAME=$( basename $0 )
NOW=$(date +%s)

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

# check if input is a number, returns false or the number itself
function check_noteID() {
	IN=$1
	case $IN in
		''|*[!0-9]*)
			return 1
			;;
		*)
			echo $IN
			;;
	esac
}

function helptext() {
    echo "Usage:"
    echo "  $0 [PARAMS] ..."
    echo ""
	cat << __NOWCONF__ 
${BASENAME} configuration is:

base directory:		${BASEDIR}/
notes archive:		${NOTESDIR}/
notes database:		${DB}
rc file:		$RCFILE

text editor:		${EDITOR}
terminal:		${TERMINAL}
jq executable:		${JQ}
__NOWCONF__

	echo ""
    echo "${BASENAME} parameters are:"
    echo "  -h | --help			: This help text"
    echo "  -p | --plain			: Output is in plain text"
    echo "				  (without this option the output is colored)"
    echo "  -l | --list			: List existing notes"
    echo "  -a | --add <title>		: Add new note"
    echo "  -m | --modify <note> 		: Modify note"
    echo "  -d | --date <note> 		: Modify date for note"
    echo "  -r | --remove <note>		: Remove note"
    echo "  -v | --version		: Print version"
    echo "  --userconf			: Export User config file"
    echo ""
}

function addnote() {
	NOTETITLE="$1"
	echo "adding new note - \"$NOTETITLE\""
	LASTID=$($JQ '.notes[-1].id // 0 | tonumber' $DB)
	# [ "" == $LASTID ] && LASTID=0
	NOTEID=$(( $LASTID + 1 ))
	touch ${NOTESDIR}/${NOW}
	$JQ --arg i "$NOTEID" --arg t "$NOTETITLE" --arg f "$NOW" '.notes += [{"id": $i, "title": $t, "file": $f}]' "$DB" > $TMPDB
	mv $TMPDB $DB
	$(${TERMINAL} ${TERM_OPTS} ${EDITOR} ${NOTESDIR}/${NOW})
}

function listnotes() {
	# [ $PLAIN == true ] && echo "output is plain text" || echo "output is colored"
	if [[ $(ls -A $NOTESDIR) ]]; then
		echo "listing all notes"
		echo ""
		echo "[ID]	[TITLE]		[SIZE]"
		for i in ${NOTESDIR}/*; do
			SIZE=$(du -k $i |cut -f 1)
			TITLE=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .title' $DB)
			ID=$($JQ -r --arg z $(basename $i) '.notes[] | select(.file == $z) | .id' $DB)

			echo "[${ID}]	${TITLE}	${SIZE}kb"
		done
	else
		echo "no notes yet. You can add your first one with: ${BASENAME} -a \"your note title\""
	fi
}

function editnote() {
	NOTE=$1
	local OK=$(check_noteID $NOTE)
	if [ ! $OK ]; then
		echo "invalid note \"$NOTE\""
		exit 1
	fi

	TITLE=$($JQ --arg i $OK '.notes[] | select(.id == $i) | .title' $DB)
	FILE=$($JQ -r --arg i $OK '.notes[] | select(.id == $i) | .file' $DB)
	if [ "$TITLE" ]; then
		echo "editing note $TITLE"
		$(${TERMINAL} --class notes --title notes -e ${EDITOR} ${NOTESDIR}/${FILE})
	else
		 echo "note not found"
		 exit 1
	fi
}

function datenote() {
	NOTE=$1
	local OK=$(check_noteID $NOTE)
	[ $OK ] && echo "editing date for note $OK" || echo "invalid note \"$NOTE\""
	# FILEDATE=$(date -d @$NOW +%d/%m/%Y_%T)

}

function rmnote() {
	NOTE=$1
	local OK=$(check_noteID $NOTE)
	[ $OK ] && echo "removing note $OK" || echo "invalid note \"$NOTE\""
}

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

	read -r -p "Do you wish to continue? (y/N) " ANSWER
	case $ANSWER in
		y|Y )
			mkdir -p $NOTESDIR
			cat << __EOL__ > ${DB}
{
	"params": {
		"version": "${VERSION}",
		"dbversion": "${NOW}"
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

# NOTE: This requires GNU getopt.  On Mac OS X and FreeBSD, you have to install this
# separately; see below.
GOPT=`getopt -o hvpla:m:d:r: --long help,version,list,plain,userconf,add:,modify:,date:,remove:,editor:,storage: \
             -n 'bash-notes' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

# Note the quotes around `$GOPT': they are essential!
eval set -- "$GOPT"

PLAIN=false

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
		--userconf )
			export_config
			echo "config exported to \"$RCFILE\""
			exit
			;;
		-- )
			shift; break
			;;
		* )
			break
			;;
	esac
done

