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
# Address of your remote repository
GITREMOTE=${GITREMOTE:-""}
# How long should we wait (in seconds) between sync on the git remote. Default 3600 (1 hour)
GITSYNCDELAY=${GITSYNCDELAY:-"3600"}
# The name of this client. Defaults to the output of hostname
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
