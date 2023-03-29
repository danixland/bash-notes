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
    echo "  $0 [PARAMS] ..."
    echo ""
	cat << __NOWCONF__ 
${BASENAME} configuration is:

base directory:		${BASEDIR}/
notes archive:		${NOTESDIR}/
notes database:		${DB}
rc file:		$RCFILE
debug file:		/tmp/debug_bash-note.log

text editor:		${EDITOR}
terminal:		${TERMINAL}
jq executable:		${JQ}
__NOWCONF__

	echo ""
    echo "${BASENAME} parameters are:"
    echo "  -h | --help			: This help text"
    echo "  -p | --plain			: Output is in plain text"
    echo "				  (without this option the output is formatted)"
    echo "				  (this option must precede all others)"
    echo "  -l | --list			: List existing notes"
    echo "  -a | --add [\"<title>\"]	: Add new note"
    echo "  -e | --edit [<note>]	 	: Edit note"
    echo "  -d | --delete [<note> | all]	: Delete single note or all notes at once"
    echo "	-s | --show [<note>]		: Display note using your favourite PAGER"
    echo "  -v | --version		: Print version"
    echo "  --userconf			: Export User config file"
    echo ""
}
