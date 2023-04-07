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

