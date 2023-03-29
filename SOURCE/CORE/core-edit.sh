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
