# check if input is a number, returns false or the number itself
check_noteID() {
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
    echo ""
    echo -e "if a non option is passed and is a valid note ID, the note will be displayed."
}

configtext() {
    [ $USEGIT ] && GITUSE="enabled" || GITUSE="disabled"
    clear
    echo -e "${BASENAME} configuration is:"

    echo -e "base directory:     ${BASEDIR}/"
    echo -e "notes archive:      ${NOTESDIR}/"
    echo -e "notes database:     ${DB}"
    echo -e "rc file:            $RCFILE"
    echo -e "debug file:         /tmp/debug_bash-note.log"

    echo -e "text editor:        ${EDITOR}"
    echo -e "terminal:           ${TERMINAL}"
    echo -e "jq executable:      ${JQ}"
    echo -e "PAGER:              ${PAGER}"

    echo -e "GIT use:            ${GITUSE}"
    echo -e "GIT remote:         ${GITREMOTE}"
    echo -e "GIT sync delay:     ${GITSYNCDELAY}"
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

